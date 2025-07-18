package main

import (
	"fmt"
	"os"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func main() {
	chaincode, err := contractapi.NewChaincode(new(KVContract))
	if err != nil {
		fmt.Printf("Error creating KVChaincode: %s", err.Error())
		os.Exit(1)
	}

	// The 'Start()' method of contractapi.Chaincode will automatically
	// handle the gRPC server setup, including TLS based on environment variables
	// like CORE_CHAINCODE_TLS_ENABLED, CORE_CHAINCODE_TLS_KEY, CORE_CHAINCODE_TLS_CERT, etc.
	// This is the beauty of the contract API - it abstracts away the shim details.
	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting KVChaincode: %s", err.Error())
		os.Exit(1)
	}
}