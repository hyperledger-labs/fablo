function networkUp() {
  printf "============ \U1F913 Generating basic configs \U1F913 =================================== \n"
  certsGenerate "fabric-config" "./fabric-config/crypto-config"
  genesisBlockCreate "fabric-config" "./fabric-config/config"

  printf "============ \U1F680 Starting network \U1F680 =========================================== \n"
  cd fabric-compose
  docker-compose up -d
  cd ..
  sleep 4

  printf "============ \U1F913 Generating config for 'channel1' \U1F913 =========================== \n"
  createChannelTx "channel1" "fabric-config" "OneOrgChannel" "./fabric-config/config" "Org1MSP"
  createAnchorPeerUpdateTx "channel1" "fabric-config" "OneOrgChannel" "./fabric-config/config" "Org1MSP"

  printf "============ \U1F63B Creating 'channel1' on org1's anchor peer \U1F63B ================== \n"
  docker exec -it cli.org1 bash -c \
    "source scripts/channel_fns.sh; createChannelAndJoin 'channel1' 'Org1MSP' 'peer0.org1.com:7051' 'crypto/peerOrganizations/org1.com/users/Admin@org1.com/msp' 'orderer.example.com:7050';"

  #docker exec -it cli bash -c \
  #  "source scripts/channel_fns.sh; fetchChannelAndJoin 'channel1' 'Org1MSP' 'peer1.org1.com:7051' 'crypto/peerOrganizations/org1.com/users/Admin@org1.com/msp' 'orderer.example.com:7050';"

  printf "============ \U1F60E Installing 'chaincode1' on channel1/org1/peer \U1F60E ============== \n"
  chaincodeInstall "chaincode1" "0.0.1" "java" "channel1" "peer0.org1.com:7051" "orderer.example.com:7050" "cli.org1"
  chaincodeInstantiate "chaincode1" "0.0.1" "java" "channel1" "peer0.org1.com:7051" "orderer.example.com:7050" "cli.org1" '{"Args":[]}' "AND ('Org1MSP.member')"

  printf "============ \U1F984 Done! Enjoy your fresh network \U1F984 ============================= \n"
}

function installChaincodes() {
  printf "============ \U1F60E Installing 'chaincode1' on channel1/org1/peer \U1F60E ============== \n"
  chaincodeInstall "chaincode1" "0.0.1" "java" "channel1" "peer0.org1.com:7051" "orderer.example.com:7050" "cli.org1"
  chaincodeInstantiate "chaincode1" "0.0.1" "java" "channel1" "peer0.org1.com:7051" "orderer.example.com:7050" "cli.org1" '{"Args":[]}' "AND ('Org1MSP.member')"
}

function networkDown() {
  printf "============ \U1F916 Stopping network \U1F916 =========================================== \n"
  cd fabric-compose
  docker-compose down
  cd ..

  printf "\nRemoving generated configs (base-commands)... \U1F5D1 \n"
  rm -rf fabric-config/config
  rm -rf fabric-config/crypto-config

  printf "============ \U1F5D1 Done! Network was purged \U1F5D1 =================================== \n"
}

function networkRerun() {
  networkDown
  networkUp
}

# TODO 1 - na koniec powinien polecieć anchorPeerUpdate
# TODO 2 - pamiętaj żeby skorzystać z odpowiedniego cli w przypadku organizacji
# TODO 3 - pomyśl o tym jak konfigurowac anchor peer'a
# TODO 4 - try/catch w bashu

# TODO 1 - kiedy skrypt będzie generyczny ?
# TODO 2 - fajnie to by było mieć channel.tx jako "bloba"
