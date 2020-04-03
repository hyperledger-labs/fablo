function networkUp() {
  printf "============ \U1F913 Generating basic configs \U1F913 =================================== \n"
  certsGenerate "fabric-config" "crypto-config-root.yaml" "./fabric-config/crypto-config/"
  <% orgs.forEach(function(org){  %>
  printf "===== \U1F512 Generating crypto material for <%= org.organization.name %> \U1F512 ===== \n"
  certsGenerate "fabric-config" "crypto-config-<%= org.organization.name.toLowerCase() %>.yaml" "./fabric-config/crypto-config/"
  <% }) %>

  printf "===== \U1F3E0 Generating genesis block \U1F3E0 ===== \n"
  genesisBlockCreate "fabric-config" "./fabric-config/config"

  printf "============ \U1F680 Starting network \U1F680 =========================================== \n"
  cd fabric-compose
  docker-compose up -d
  cd ..
  sleep 4

  <% channels.forEach(function(channel){  -%>
  printf "============ \U1F913 Generating config for '<%= channel.name %>' \U1F913 =========================== \n"
  createChannelTx "<%= channel.name %>" "fabric-config" "AllOrgChannel" "./fabric-config/config"
  <% for (orgNo in channel.orgs) {
      var org = channel.orgs[orgNo]
  -%>
  <% for (peerNo in org.peers) {
      var peer = org.peers[peerNo]
  -%>

  <% if(orgNo==0 && peerNo==0) { -%>
  printf "============ \U1F63B Creating '<%= channel.name %>' on <%= org.name %>/<%= peer.name %> \U1F63B ================== \n"
  docker exec -it cli.<%= org.domain %> bash -c \
    "source scripts/channel_fns.sh; createChannelAndJoin '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.address %>:7051' 'crypto/peerOrganizations/<%= org.domain %>/users/Admin@<%= org.domain %>/msp' '<%= rootOrg.ordererHead.address %>:7050';"
  <% } else { -%>
  printf "====== \U1F638 Joining '<%= channel.name %>' on  <%= org.name %>/<%= peer.name %> \U1F638 ====== \n"
  docker exec -it cli.<%= org.domain %> bash -c \
    "source scripts/channel_fns.sh; fetchChannelAndJoin '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.address %>:7051' 'crypto/peerOrganizations/<%= org.domain %>/users/Admin@<%= org.domain %>/msp' '<%= rootOrg.ordererHead.address %>:7050';"
  <% } -%>
  <% } -%>
  <% } -%>
  <% }) -%>

  printf "============ \U1F60E Installing 'chaincode1' on channel1/org1/peer \U1F60E ============== \n"
  chaincodeInstall "chaincode1" "0.0.1" "java" "channel1" "peer0.org1.com:7051" "orderer0.example.com:7050" "cli.org1.com" # TODO to mi sie nie podoba. a gdzie uprawnienia ?
  chaincodeInstantiate "chaincode1" "0.0.1" "java" "channel1" "peer0.org1.com:7051" "orderer0.example.com:7050" "cli.org1.com" '{"Args":[]}' "AND ('Org1MSP.member')"

  printf "============ \U1F984 Done! Enjoy your fresh network \U1F984 ============================= \n"
}

function installChaincodes() {
  printf "============ \U1F60E Installing 'chaincode1' on channel1/org1/peer \U1F60E ============== \n"
  chaincodeInstall "chaincode1" "0.0.1" "java" "channel1" "peer0.org1.com:7051" "orderer0.example.com:7050" "cli.org1.com"
  chaincodeInstantiate "chaincode1" "0.0.1" "java" "channel1" "peer0.org1.com:7051" "orderer0.example.com:7050" "cli.org1.com" '{"Args":[]}' "AND ('Org1MSP.member')"
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
