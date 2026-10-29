module github.com/hyperledger-labs/fablo/e2e-network/docker/fabric-x-app

go 1.26.3

// Versions match github.com/hyperledger/fabric-x-samples/custom-endorser and the
// committer image used by Fablo. Run "go mod tidy" once to create go.sum and the
// indirect requirements, then commit both files.
require (
	github.com/hyperledger/fabric-x-committer v1.0.3
	github.com/hyperledger/fabric-x-common v0.2.6
	github.com/hyperledger/fabric-x-samples/custom-endorser v0.0.0-20260924150640-e97194ea7e56
	github.com/hyperledger/fabric-x-sdk v0.0.0-20260618080057-dddd57eee118
	google.golang.org/grpc v1.81.1
)
