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
	channel   string
	namespace string
	mspID     string
	orderer   string
	sidecar   string
	mspDir        string
	tlsDir        string
	orgTLSCA      string
	ordererCAGlob string

	timeout time.Duration
}

func parseOptions() (options, error) {
	var o options
	flag.StringVar(&o.channel, "channel", "", "channel name (required)")
	flag.StringVar(&o.namespace, "namespace", "", "namespace to write to (required)")
	flag.StringVar(&o.mspID, "msp-id", "", "MSP ID of the signing identity (required)")
	flag.StringVar(&o.orderer, "orderer", "", "address of the orderer router, host:port (required)")
	flag.StringVar(&o.sidecar, "sidecar", "", "address of the committer sidecar, host:port (required)")
	flag.StringVar(&o.mspDir, "msp-dir", "/msp", "MSP directory of the signing identity")
	flag.StringVar(&o.tlsDir, "tls-dir", "/tls", "directory with the client TLS certificate (server.crt and server.key)")
	flag.StringVar(&o.orgTLSCA, "org-tls-ca", "/org-tls-ca.pem", "TLS CA certificate of the application org")
	flag.StringVar(&o.ordererCAGlob, "orderer-tls-ca-glob", "/orderer-cas/*/msp/tlscacerts/*.pem", "pattern of the TLS CA certificates of the orderer orgs")
	flag.DurationVar(&o.timeout, "timeout", 90*time.Second, "overall timeout")
	flag.Parse()

	required := []struct{ name, value string }{
		{"channel", o.channel},
		{"namespace", o.namespace},
		{"msp-id", o.mspID},
		{"orderer", o.orderer},
		{"sidecar", o.sidecar},
	}
	for _, r := range required {
		if r.value == "" {
			return o, fmt.Errorf("flag -%s is required", r.name)
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
	ctx, cancel := context.WithTimeout(ctx, o.timeout)
	defer cancel()

	logger := sdk.NewStdLogger("fabric-x-app")

	signer, err := identity.SignerFromMSP(o.mspDir, o.mspID)
	if err != nil {
		return fmt.Errorf("load signer: %w", err)
	}

	ordererCAs, err := filepath.Glob(o.ordererCAGlob)
	if err != nil {
		return fmt.Errorf("find orderer TLS CAs: %w", err)
	}
	if len(ordererCAs) == 0 {
		return fmt.Errorf("no orderer TLS CA certificate matches %s", o.ordererCAGlob)
	}


	clientTLS := func(cas []string) network.TLSConfig {
		return network.TLSConfig{
			Mode:        network.TLSModeMTLS,
			CertPath:    filepath.Join(o.tlsDir, "server.crt"),
			KeyPath:     filepath.Join(o.tlsDir, "server.key"),
			CACertPaths: cas,
		}
	}
	sidecar := network.PeerConf{Address: o.sidecar, TLS: clientTLS([]string{o.orgTLSCA})}
	orderer := network.OrdererConf{Address: o.orderer, TLS: clientTLS(append(ordererCAs, o.orgTLSCA))}

	
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
	defer func() { _ = ec.Close() }()

	submitter, err := nfabx.NewSubmitter(ctx, []network.OrdererConf{orderer}, signer, 0, logger)
	if err != nil {
		return fmt.Errorf("create submitter: %w", err)
	}
	defer func() { _ = submitter.Close() }()
	existing, err := read(ctx, ec, o.namespace, fixtureKey)
	if err != nil {
		return err
	}
	if len(existing) != 0 {
		return fmt.Errorf("key %q already has the value %q in namespace %s, run the fixture on a fresh network", fixtureKey, existing, o.namespace)
	}
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
		return "", errors.New("the endorser did not catch up with the sidecar before the timeout")
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
	if len(end.Responses) != 1 || end.Responses[0] == nil || end.Responses[0].Response == nil {
		return sdk.Endorsement{}, nil, fmt.Errorf("endorse %s: expected exactly one response", args[0])
	}
	resp := end.Responses[0].Response
	if resp.Status < 200 || resp.Status >= 400 {
		return sdk.Endorsement{}, nil, fmt.Errorf("endorse %s: status %d: %s", args[0], resp.Status, resp.Message)
	}
	return end, resp.Payload, nil
}
func read(ctx context.Context, ec *network.EndorsementClient, namespace, key string) ([]byte, error) {
	_, payload, err := endorse(ctx, ec, namespace, "get", key)
	return payload, err
}
func waitForValue(ctx context.Context, ec *network.EndorsementClient, namespace, key, want string) error {
	var last []byte
	var lastErr error
	for {
		last, lastErr = read(ctx, ec, namespace, key)
		if lastErr == nil && string(last) == want {
			return nil
		}

		select {
		case <-ctx.Done():
			return fmt.Errorf("key %q in namespace %s never had value %q (last value %q, last error %v)", key, namespace, want, last, lastErr)
		case <-time.After(pollInterval):
		}
	}
}