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

func (c *KVContract) Put(ctx contractapi.TransactionContextInterface, key string, value string) (map[string]string, error) {
	err := ctx.GetStub().PutState(key, []byte(value))
	if err != nil {
		return map[string]string{"error": err.Error()}, err
	}
	return map[string]string{"success": "OK"}, nil
}

func (c *KVContract) Get(ctx contractapi.TransactionContextInterface, key string) (map[string]string, error) {
	buffer, err := ctx.GetStub().GetState(key)
	if err != nil {
		return map[string]string{"error": err.Error()}, err
	}
	if buffer == nil || len(buffer) == 0 {
		return map[string]string{"error": "NOT_FOUND"}, nil
	}
	return map[string]string{"success": string(buffer)}, nil
}

func (c *KVContract) PutPrivateMessage(ctx contractapi.TransactionContextInterface, collection string) (map[string]string, error) {
	transientMap, err := ctx.GetStub().GetTransient()
	if err != nil {
		return map[string]string{"error": err.Error()}, err
	}
	message, exists := transientMap["message"]
	if !exists {
		return map[string]string{"error": "TRANSIENT_KEY_NOT_FOUND"}, fmt.Errorf("transient key 'message' not found")
	}
	err = ctx.GetStub().PutPrivateData(collection, "message", message)
	if err != nil {
		return map[string]string{"error": err.Error()}, err
	}
	return map[string]string{"success": "OK"}, nil
}

func (c *KVContract) GetPrivateMessage(ctx contractapi.TransactionContextInterface, collection string) (map[string]string, error) {
	message, err := ctx.GetStub().GetPrivateData(collection, "message")
	if err != nil {
		return map[string]string{"error": err.Error()}, err
	}
	if message == nil {
		return map[string]string{"error": "NOT_FOUND"}, nil
	}
	return map[string]string{"success": string(message)}, nil
}

func (c *KVContract) VerifyPrivateMessage(ctx contractapi.TransactionContextInterface, collection string) (map[string]string, error) {
	transientMap, err := ctx.GetStub().GetTransient()
	if err != nil {
		return map[string]string{"error": err.Error()}, err
	}
	messageBytes, exists := transientMap["message"]
	if !exists {
		return map[string]string{"error": "TRANSIENT_KEY_NOT_FOUND"}, fmt.Errorf("transient key 'message' not found")
	}
	hash := sha256.New()
	hash.Write(messageBytes)
	currentHash := hex.EncodeToString(hash.Sum(nil))

	hashBytes, err := ctx.GetStub().GetPrivateDataHash(collection, "message")
	if err != nil {
		return map[string]string{"error": err.Error()}, err
	}
	storedHash := hex.EncodeToString(hashBytes)

	if storedHash != currentHash {
		return map[string]string{"error": "VERIFICATION_FAILED"}, nil
	}
	return map[string]string{"success": "OK"}, nil
}