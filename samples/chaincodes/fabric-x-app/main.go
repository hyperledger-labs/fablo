// Command fabric-x-app is a small application fixture for the Fabric-X e2e test.
//
// It follows the external endorser model. The program starts an endorser for one
// namespace, then acts as the client:
//
//  1. send a "set" proposal to the endorser
//  2. submit the endorsed transaction to the orderer
//  3. wait for the commit notification from the sidecar
//  4. read the key back through the endorser
//
// The key and value are constants, so a successful run always prints the same line.
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"net"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"

	"github.com/hyperledger/fabric-x-committer/utils/serve"
	"github.com/hyperledger/fabric-x-common/protoutil"
	"github.com/hyperledger/fabric-x-samples/custom-endorser/service"
	sdk "github.com/hyperledger/fabric-x-sdk"
	"github.com/hyperledger/fabric-x-sdk/identity"
	"github.com/hyperledger/fabric-x-sdk/network"
	nfabx "github.com/hyperledger/fabric-x-sdk/network/fabricx"
	"github.com/hyperledger/fabric-x-sdk/notification"
	"google.golang.org/grpc"
)

const (
	fixtureKey   = "fixture-key"
	fixtureValue = "fixture-value"
	nsVersion    = "1.0"
)

type options struct {
	channel       string
	mspID         string
	mspDir        string
	namespace     string
	tlsDir        string
	orgTLSCA      string
	ordererTLSCA  string
	orderer       string
	sidecar       string
	overallTimeout time.Duration
}

func parseOptions() options {
	var o options
	flag.StringVar(&o.channel, "channel", "mychannel", "channel name")
	flag.StringVar(&o.mspID, "msp-id", "Org1MSP", "MSP ID of the signing identity")
	flag.StringVar(&o.mspDir, "msp-dir", "/msp", "MSP directory of the signing identity")
	flag.StringVar(&o.namespace, "namespace", "mynamespace", "namespace to write to")
	flag.StringVar(&o.tlsDir, "tls-dir", "/tls", "directory with the client TLS certificate (server.crt and server.key)")
	flag.StringVar(&o.orgTLSCA, "org-tls-ca", "/org-tls-ca.pem", "TLS CA certificate of the application org")
	flag.StringVar(&o.ordererTLSCA, "orderer-tls-ca", "/orderer-tls-ca.pem", "TLS CA certificate of the orderer org")
	flag.StringVar(&o.orderer, "orderer", "orderer-router:7050", "orderer router address")
	flag.StringVar(&o.sidecar, "sidecar", "committer-org1-sidecar:4001", "committer sidecar address")
	flag.DurationVar(&o.overallTimeout, "timeout", 90*time.Second, "overall timeout for the whole run")
	flag.Parse()
	return o
}

func main() {
	if err := run(parseOptions()); err != nil {
		fmt.Fprintln(os.Stderr, "FABRIC_X_APP_FAILED:", err)
		os.Exit(1)
	}
}

func run(o options) error {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	ctx, cancel := context.WithTimeout(ctx, o.overallTimeout)
	defer cancel()

	logger := sdk.NewStdLogger("fabric-x-app")

	signer, err := identity.SignerFromMSP(o.mspDir, o.mspID)
	if err != nil {
		return fmt.Errorf("load signer: %w", err)
	}

	// The same client certificate is used for the sidecar and the orderer, like fxconfig does.
	clientTLS := func(cas ...string) network.TLSConfig {
		return network.TLSConfig{
			Mode:        network.TLSModeMTLS,
			CertPath:    filepath.Join(o.tlsDir, "server.crt"),
			KeyPath:     filepath.Join(o.tlsDir, "server.key"),
			CACertPaths: cas,
		}
	}
	sidecar := network.PeerConf{Address: o.sidecar, TLS: clientTLS(o.orgTLSCA)}
	orderer := network.OrdererConf{Address: o.orderer, TLS: clientTLS(o.ordererTLSCA, o.orgTLSCA)}

	// Start the endorser. It keeps its own state in memory, synced from the sidecar.
	endorserAddr, err := startEndorser(ctx, o, sidecar, logger)
	if err != nil {
		return err
	}

	// The endorser is on loopback in the same process, so it does not need TLS.
	ec, err := network.NewEndorsementClient(
		[]network.PeerConf{{Address: endorserAddr, TLS: network.TLSConfig{Mode: network.TLSModeNone}}},
		signer, o.channel, o.namespace, nsVersion,
	)
	if err != nil {
		return fmt.Errorf("create endorsement client: %w", err)
	}
	defer ec.Close() //nolint:errcheck

	submitter, err := nfabx.NewSubmitter(ctx, []network.OrdererConf{orderer}, signer, 0, logger)
	if err != nil {
		return fmt.Errorf("create submitter: %w", err)
	}
	defer submitter.Close() //nolint:errcheck

	// Start listening for commit notifications before anything is submitted.
	events := make(chan notification.TxStatusEvent, 16)
	txIDs := make(chan []string, 1)
	streamDone, err := startNotifications(ctx, o, sidecar, signer, logger, events, txIDs)
	if err != nil {
		return err
	}

	// 1. endorse
	end, _, err := endorse(ctx, ec, o.namespace, "set", fixtureKey, fixtureValue)
	if err != nil {
		return err
	}
	txID, err := txIDOf(end)
	if err != nil {
		return err
	}

	// 2. submit
	txIDs <- []string{txID}
	if err := submitter.Submit(ctx, end); err != nil {
		return fmt.Errorf("submit: %w", err)
	}

	// 3. wait for commit
	if err := waitForCommit(ctx, events, streamDone, txID); err != nil {
		return err
	}

	// 4. query
	if err := waitForValue(ctx, ec, o.namespace, fixtureKey, fixtureValue); err != nil {
		return err
	}

	fmt.Printf("FABRIC_X_APP_OK namespace=%s key=%s value=%s\n", o.namespace, fixtureKey, fixtureValue)
	return nil
}

// startEndorser runs the endorser service on a random loopback port and waits
// until it has caught up with the sidecar. It stops when ctx is done.
func startEndorser(ctx context.Context, o options, sidecar network.PeerConf, logger sdk.Logger) (string, error) {
	svc, err := service.New(
		service.ServiceConfig{
			ChannelID: o.channel,
			Protocol:  "fabric-x",
			Committer: sidecar,
			DBConnStr: "file:fabric-x-app.sqlite?mode=memory&cache=shared",
		},
		o.mspDir, o.mspID,
		map[string]service.Executor{o.namespace: Executor{}},
		logger,
	)
	if err != nil {
		return "", fmt.Errorf("create endorser: %w", err)
	}

	lis, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return "", fmt.Errorf("listen: %w", err)
	}
	grpcServer := grpc.NewServer()
	svc.RegisterService(serve.Servers{GRPC: grpcServer})

	go func() { _ = svc.Run(ctx) }()
	go func() { _ = grpcServer.Serve(lis) }()
	go func() {
		<-ctx.Done()
		grpcServer.Stop()
	}()

	if !svc.WaitForReady(ctx) {
		return "", errors.New("endorser did not catch up with the sidecar before the timeout")
	}
	return lis.Addr().String(), nil
}

// startNotifications opens the commit notification stream. Transaction IDs sent
// on txIDs are watched and their status is delivered on events. The returned
// channel receives an error if the stream ends.
func startNotifications(
	ctx context.Context,
	o options,
	sidecar network.PeerConf,
	signer sdk.Signer,
	logger sdk.Logger,
	events chan<- notification.TxStatusEvent,
	txIDs <-chan []string,
) (<-chan error, error) {
	peer, err := nfabx.NewPeer(sidecar, o.channel, signer)
	if err != nil {
		return nil, fmt.Errorf("create sidecar client: %w", err)
	}
	processor := notification.NewProcessor([]notification.TxStatusHandler{chanHandler{out: events}}, logger)
	notifier := notification.NewNotifier(peer, processor)
	notifier.SetDefaultTimeout(o.overallTimeout)

	done := make(chan error, 1)
	go func() {
		defer peer.Close() //nolint:errcheck
		done <- notifier.Subscribe(ctx, txIDs)
	}()
	return done, nil
}

// chanHandler forwards transaction status events to a channel.
type chanHandler struct {
	out chan<- notification.TxStatusEvent
}

func (h chanHandler) Handle(ctx context.Context, events []notification.TxStatusEvent) error {
	for _, ev := range events {
		select {
		case h.out <- ev:
		case <-ctx.Done():
			return ctx.Err()
		}
	}
	return nil
}

// endorse sends one proposal to the endorser and returns the endorsement and the response payload.
func endorse(ctx context.Context, ec *network.EndorsementClient, namespace string, args ...string) (sdk.Endorsement, []byte, error) {
	raw := make([][]byte, len(args))
	for i, a := range args {
		raw[i] = []byte(a)
	}
	end, err := ec.ExecuteTransaction(ctx, namespace, nsVersion, raw)
	if err != nil {
		return sdk.Endorsement{}, nil, fmt.Errorf("endorse %s: %w", args[0], err)
	}
	if len(end.Responses) != 1 {
		return sdk.Endorsement{}, nil, fmt.Errorf("endorse %s: expected 1 response, got %d", args[0], len(end.Responses))
	}
	resp := end.Responses[0].Response
	if resp.Status < 200 || resp.Status >= 400 {
		return sdk.Endorsement{}, nil, fmt.Errorf("endorse %s: status %d: %s", args[0], resp.Status, resp.Message)
	}
	return end, resp.Payload, nil
}

// txIDOf reads the transaction ID from the proposal header.
func txIDOf(end sdk.Endorsement) (string, error) {
	hdr, err := protoutil.UnmarshalHeader(end.Proposal.Header)
	if err != nil {
		return "", fmt.Errorf("read proposal header: %w", err)
	}
	chdr, err := protoutil.UnmarshalChannelHeader(hdr.ChannelHeader)
	if err != nil {
		return "", fmt.Errorf("read channel header: %w", err)
	}
	return chdr.TxId, nil
}

// waitForCommit blocks until the sidecar reports the status of txID.
func waitForCommit(ctx context.Context, events <-chan notification.TxStatusEvent, streamDone <-chan error, txID string) error {
	for {
		select {
		case ev := <-events:
			if ev.TxID != txID {
				continue
			}
			if !ev.Valid() {
				return fmt.Errorf("tx %s was not committed: status %v at block %d", txID, ev.Status, ev.BlockNum)
			}
			return nil
		case err := <-streamDone:
			return fmt.Errorf("notification stream ended before tx %s was committed: %v", txID, err)
		case <-ctx.Done():
			return fmt.Errorf("waiting for commit of tx %s: %w", txID, ctx.Err())
		}
	}
}

// waitForValue reads the key through the endorser until it has the wanted value.
// The endorser syncs from the sidecar, so it can be a few moments behind the commit.
func waitForValue(ctx context.Context, ec *network.EndorsementClient, namespace, key, want string) error {
	var last string
	var lastErr error
	for {
		_, payload, err := endorse(ctx, ec, namespace, "get", key)
		if err == nil && string(payload) == want {
			return nil
		}
		last, lastErr = string(payload), err

		select {
		case <-ctx.Done():
			return fmt.Errorf("key %q in namespace %s never had value %q (last value %q, last error %v)", key, namespace, want, last, lastErr)
		case <-time.After(250 * time.Millisecond):
		}
	}
}
