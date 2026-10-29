
package main

import (
	"context"
	"fmt"

	"github.com/hyperledger/fabric-x-samples/custom-endorser/service"
	"github.com/hyperledger/fabric-x-sdk/endorsement"
)

type Executor struct{}


func (Executor) Execute(_ context.Context, newStore service.StoreFactory, inv endorsement.Invocation) (endorsement.ExecutionResult, error) {

	store, err := newStore(0)
	if err != nil {
		return endorsement.ExecutionResult{}, fmt.Errorf("simulation store: %w", err)
	}

	if len(inv.Args) == 0 {
		return endorsement.BadRequest("no function specified"), nil
	}

	switch string(inv.Args[0]) {
	case "get":
		if len(inv.Args) < 2 {
			return endorsement.BadRequest("usage: get [key]"), nil
		}
		value, err := store.GetState(string(inv.Args[1]))
		if err != nil {
			return endorsement.ExecutionResult{}, fmt.Errorf("get state: %w", err)
		}
		return endorsement.Success(store.Result(), nil, value), nil

	case "set":
		if len(inv.Args) < 3 {
			return endorsement.BadRequest("usage: set [key] [value]"), nil
		}
		
		if err := store.PutState(string(inv.Args[1]), inv.Args[2]); err != nil {
			return endorsement.ExecutionResult{}, fmt.Errorf("put state: %w", err)
		}
		return endorsement.Success(store.Result(), nil, fmt.Appendf(nil, "%s=%s", inv.Args[1], inv.Args[2])), nil

	default:
		return endorsement.BadRequest("usage: get [key] || set [key] [value]"), nil
	}
}
