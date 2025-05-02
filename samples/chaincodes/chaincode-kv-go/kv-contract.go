package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type Response struct {
	Success string `json:"success,omitempty"`
	Error   string `json:"error,omitempty"`
}

type KVContract struct {
	contractapi.Contract
}

func (c *KVContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	return nil
}

func (c *KVContract) Put(ctx contractapi.TransactionContextInterface, key string, value string) (*Response, error) {
	err := ctx.GetStub().PutState(key, []byte(value))
	if err != nil {
		return &Response{Error: err.Error()}, err
	}
	return &Response{Success: "OK"}, nil
}

func (c *KVContract) Get(ctx contractapi.TransactionContextInterface, key string) (*Response, error) {
	buffer, err := ctx.GetStub().GetState(key)
	if err != nil {
		return &Response{Error: err.Error()}, err
	}
	if buffer == nil || len(buffer) == 0 {
		return &Response{Error: "NOT_FOUND"}, nil
	}
	return &Response{Success: string(buffer)}, nil
}

func (c *KVContract) PutPrivateMessage(ctx contractapi.TransactionContextInterface, collection string) (*Response, error) {
	transientMap, err := ctx.GetStub().GetTransient()
	if err != nil {
		return &Response{Error: err.Error()}, err
	}
	message, exists := transientMap["message"]
	if !exists {
		return &Response{Error: "TRANSIENT_KEY_NOT_FOUND"}, fmt.Errorf("transient key 'message' not found")
	}
	err = ctx.GetStub().PutPrivateData(collection, "message", message)
	if err != nil {
		return &Response{Error: err.Error()}, err
	}
	return &Response{Success: "OK"}, nil
}

func (c *KVContract) GetPrivateMessage(ctx contractapi.TransactionContextInterface, collection string) (*Response, error) {
	message, err := ctx.GetStub().GetPrivateData(collection, "message")
	if err != nil {
		return &Response{Error: err.Error()}, err
	}
	if message == nil {
		return &Response{Error: "NOT_FOUND"}, nil
	}
	return &Response{Success: string(message)}, nil
}

func (c *KVContract) VerifyPrivateMessage(ctx contractapi.TransactionContextInterface, collection string) (*Response, error) {
	transientMap, err := ctx.GetStub().GetTransient()
	if err != nil {
		return &Response{Error: err.Error()}, err
	}
	messageBytes, exists := transientMap["message"]
	if !exists {
		return &Response{Error: "TRANSIENT_KEY_NOT_FOUND"}, fmt.Errorf("transient key 'message' not found")
	}
	hash := sha256.New()
	hash.Write(messageBytes)
	currentHash := hex.EncodeToString(hash.Sum(nil))

	hashBytes, err := ctx.GetStub().GetPrivateDataHash(collection, "message")
	if err != nil {
		return &Response{Error: err.Error()}, err
	}
	storedHash := hex.EncodeToString(hashBytes)

	if storedHash != currentHash {
		return &Response{Error: "VERIFICATION_FAILED"}, nil
	}
	return &Response{Success: "OK"}, nil
}