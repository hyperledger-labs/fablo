
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
	"github.com/hyperledger/fabric-x-samples/custom-endorser/service"
	sdk "github.com/hyperledger/fabric-x-sdk"
	"github.com/hyperledger/fabric-x-sdk/identity"
	"github.com/hyperledger/fabric-x-sdk/network"
	nfabx "github.com/hyperledger/fabric-x-sdk/network/fabricx"
	"google.golang.org/grpc"
)

const (
	fixtureKey   = "fixture-key"
	fixtureValue = "fixture-value"
	nsVersion    = "1.0"
	pollInterval = 250 * time.Millisecond
)

type options struct {
	channel        string
	mspID          string
	mspDir         string
	namespace      string
	tlsDir         string
	orgTLSCA       string
	ordererTLSCA   string
	orderer        string
	sidecar        string
	overallTimeout time.Duration
}

func parseOptions() (options, error) {
	var o options
	flag.StringVar(&o.channel, "channel", "", "channel name (required)")
	flag.StringVar(&o.mspID, "msp-id", "", "MSP ID of the signing identity (required)")
	flag.StringVar(&o.namespace, "namespace", "", "namespace to write to (required)")
	flag.StringVar(&o.orderer, "orderer", "", "orderer router address, host:port (required)")
	flag.StringVar(&o.sidecar, "sidecar", "", "committer sidecar address, host:port (required)")
	flag.StringVar(&o.mspDir, "msp-dir", "/msp", "MSP directory of the signing identity")
	flag.StringVar(&o.tlsDir, "tls-dir", "/tls", "directory with the client TLS certificate (server.crt and server.key)")
	flag.StringVar(&o.orgTLSCA, "org-tls-ca", "/org-tls-ca.pem", "TLS CA certificate of the application org")
	flag.StringVar(&o.ordererTLSCA, "orderer-tls-ca", "/orderer-tls-ca.pem", "TLS CA certificate of the orderer org")
	flag.DurationVar(&o.overallTimeout, "timeout", 90*time.Second, "overall timeout for the whole run")
	flag.Parse()

	for name, v := range map[string]string{
		"channel": o.channel, "msp-id": o.mspID, "namespace": o.namespace,
		"orderer": o.orderer, "sidecar": o.sidecar,
	} {
		if v == "" {
			return o, fmt.Errorf("missing required flag --%s", name)
		}
	}
	return o, nil
}

func main() {
	o, err := parseOptions()
	if err == nil {
		err = run(o)
	}
	if err != nil {
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

	endorserAddr, err := startEndorser(ctx, o, sidecar, logger)
	if err != nil {
		return err
	}

	ec, err := network.NewEndorsementClient(
		[]network.PeerConf{{Address: endorserAddr, TLS: network.TLSConfig{Mode: network.TLSModeNone}}},
		signer, o.channel, o.namespace, nsVersion,
	)
	if err != nil {
		return fmt.Errorf("create endorsement client: %w", err)
	}
	defer ec.Close()

	submitter, err := nfabx.NewSubmitter(ctx, []network.OrdererConf{orderer}, signer, 0, logger)
	if err != nil {
		return fmt.Errorf("create submitter: %w", err)
	}
	defer submitter.Close()


	end, _, err := endorse(ctx, ec, o.namespace, "set", fixtureKey, fixtureValue)
	if err != nil {
		return err
	}
	if err := submitter.Submit(ctx, end); err != nil {
		return fmt.Errorf("submit: %w", err)
	}


	if err := waitForValue(ctx, ec, o.namespace, fixtureKey, fixtureValue); err != nil {
		return err
	}

	fmt.Printf("FABRIC_X_APP_OK namespace=%s key=%s value=%s\n", o.namespace, fixtureKey, fixtureValue)
	return nil
}


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
		case <-time.After(pollInterval):
		}
	}
}
