
package main

import (
	"context"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-protos-go-apiv2/peer"
	sdk "github.com/hyperledger/fabric-x-sdk"
	"github.com/hyperledger/fabric-x-sdk/blocks"
	"github.com/hyperledger/fabric-x-sdk/endorsement"
	efab "github.com/hyperledger/fabric-x-sdk/endorsement/fabric"
	efabx "github.com/hyperledger/fabric-x-sdk/endorsement/fabricx"
	"github.com/hyperledger/fabric-x-sdk/identity"
	"github.com/hyperledger/fabric-x-sdk/network"
	nfabx "github.com/hyperledger/fabric-x-sdk/network/fabricx"
	"github.com/hyperledger/fabric-x-sdk/state"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)


type Executor interface {
	Execute(context.Context, StoreFactory, endorsement.Invocation) (endorsement.ExecutionResult, error)
}


type StateStore interface {
	GetState(key string) ([]byte, error)
	PutState(key string, value []byte) error
	Result() blocks.ReadWriteSet
}

type StoreFactory func(blockNum uint64) (StateStore, error)

type endorserConfig struct {
	channelID string
	committer network.PeerConf
	dbConnStr string
}


type endorser struct {
	peer.EndorserServer
	channel      string
	synchronizer *network.Synchronizer
	executors    map[string]Executor
	builder      endorsement.Builder
	writeDB      *state.VersionedDB
	readDB       *state.VersionedDB
	logger       sdk.Logger
}

func newEndorser(cfg endorserConfig, mspDir, mspName string, executors map[string]Executor, logger sdk.Logger) (*endorser, error) {
	signer, err := identity.SignerFromMSP(mspDir, mspName)
	if err != nil {
		return nil, fmt.Errorf("failed to load signer: %w", err)
	}

	writeDB, err := state.NewWriteDB(cfg.channelID, cfg.dbConnStr)
	if err != nil {
		return nil, fmt.Errorf("db: %w", err)
	}
	readDB, err := state.NewReadDB(cfg.channelID, cfg.dbConnStr)
	if err != nil {
		return nil, fmt.Errorf("db: %w", err)
	}

	sync, err := nfabx.NewSynchronizer(readDB, cfg.channelID, cfg.committer, logger, writeDB)
	if err != nil {
		return nil, fmt.Errorf("create synchronizer: %w", err)
	}

	return &endorser{
		channel:      cfg.channelID,
		synchronizer: sync,
		executors:    executors,
		builder:      efabx.NewEndorsementBuilder(signer),
		writeDB:      writeDB,
		readDB:       readDB,
		logger:       logger,
	}, nil
}

func (s *endorser) register(server *grpc.Server) {
	peer.RegisterEndorserServer(server, s)
}


func (s *endorser) run(ctx context.Context) {
	go func() {
		if err := s.synchronizer.Start(ctx); err != nil && ctx.Err() == nil {
			s.logger.Errorf("synchronizer stopped: %v", err)
		}
	}()

	<-ctx.Done()
	_ = s.writeDB.Close()
	_ = s.readDB.Close()
}


func (s *endorser) waitForReady(ctx context.Context) bool {
	for {
		if err := s.synchronizer.Ready(); err == nil {
			return true
		}
		select {
		case <-ctx.Done():
			return false
		case <-time.After(100 * time.Millisecond):
		}
	}
}


func (s *endorser) ProcessProposal(ctx context.Context, prop *peer.SignedProposal) (*peer.ProposalResponse, error) {
	inv, err := efab.Parse(prop, time.Now())
	if err != nil {
		s.logger.Infof("tx=%s err=%s", inv.TxID, err)
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}
	if inv.Channel != s.channel {
		s.logger.Infof("tx=%s err=wrong channel: %s", inv.TxID, inv.Channel)
		return nil, status.Error(codes.InvalidArgument, fmt.Sprintf("channel must be %s", s.channel))
	}
	executor, ok := s.executors[inv.Namespace]
	if !ok {
		s.logger.Infof("tx=%s err=unknown namespace: %s", inv.TxID, inv.Namespace)
		return nil, status.Error(codes.InvalidArgument, fmt.Sprintf("unknown namespace: %s", inv.Namespace))
	}
	if inv.ChaincodeVersion == "" {
		inv.ChaincodeVersion = "1.0"
	}

	newStore := func(blockNum uint64) (StateStore, error) {
		return state.NewSimulationStore(ctx, s.readDB, inv.Namespace, blockNum, true)
	}

	res, err := executor.Execute(ctx, newStore, inv)
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}

	end, err := s.builder.Endorse(inv, res)
	if err != nil {
		return nil, status.Error(codes.Internal, fmt.Sprintf("endorsement: %s", err.Error()))
	}

	function := ""
	if len(inv.Args) > 0 {
		function = string(inv.Args[0])
	}
	s.logger.Infof("tx=%s st=%d ns=%s fn=%s args=%d", inv.TxID, end.Response.Status, inv.Namespace, function, max(len(inv.Args)-1, 0))

	return end, nil
}
