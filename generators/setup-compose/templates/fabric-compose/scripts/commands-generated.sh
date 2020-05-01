function installChaincodes() {
  <% chaincodes.forEach(function(chaincode) {
     chaincode.channel.orgs.forEach(function (org) {
       org.peers.forEach(function (peer) {
  %>
  printf "============ \U1F60E Installing '<%= chaincode.name %>' on <%= chaincode.channel.name %>/<%= org.name %>/<%= peer.name %> \U1F60E ============== \n"
  chaincodeInstall "<%= chaincode.directory %>" "<%= chaincode.name %>" "<%= chaincode.version %>" "java" "<%= chaincode.channel.name %>" "<%= peer.address %>:7051" "<%= rootOrg.ordererHead.address %>:7050" "cli.<%= org.domain %>" # TODO to mi sie nie podoba. a gdzie uprawnienia ?

  printf "==== \U1F618 Instantiating '<%= chaincode.name %>' on <%= chaincode.channel.name %>/<%= org.name %>/<%= peer.name %> \U1F618 ==== \n"
  chaincodeInstantiate "<%= chaincode.directory %>" "<%= chaincode.name %>" "<%= chaincode.version %>" "java" "<%= chaincode.channel.name %>" "<%= peer.address %>:7051" "<%= rootOrg.ordererHead.address %>:7050" "cli.<%= org.domain %>" "<%- chaincode.init %>" "<%- chaincode.endorsement %>"
  <% })})}) -%>
}

function networkUp() {
  printf "============ \U1F913 Generating basic configs \U1F913 =================================== \n"
  printf "===== \U1F512 Generating crypto material for org <%= rootOrg.organization.name %> \U1F512 ===== \n"
  certsGenerate "fabric-config" "crypto-config-root.yaml" "ordererOrganizations/<%= rootOrg.organization.domain %>" "./fabric-config/crypto-config/"
  <% orgs.forEach(function(org){  %>
  printf "===== \U1F512 Generating crypto material for <%= org.name %> \U1F512 ===== \n"
  certsGenerate "fabric-config" "<%= org.cryptoConfigFileName %>.yaml" "peerOrganizations/<%= org.domain %>" "./fabric-config/crypto-config/"
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
  <% if(!networkSettings.tls) { -%>
  docker exec -i cli.<%= org.domain %> bash -c \
    "source scripts/channel_fns.sh; createChannelAndJoin '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.address %>:7051' 'crypto/users/Admin@<%= org.domain %>/msp' '<%= rootOrg.ordererHead.address %>:7050';"
  <% } else { -%>
  docker exec -i cli.<%= org.domain %> bash -c \
    "source scripts/channel_fns.sh; createChannelAndJoinTls '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.address %>:7051' 'crypto/users/Admin@<%= org.domain %>/msp' 'crypto/users/Admin@<%= org.domain %>/tls' 'crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem' '<%= rootOrg.ordererHead.address %>:7050';"
  <% } %>
  <% } else { -%>
  printf "====== \U1F638 Joining '<%= channel.name %>' on  <%= org.name %>/<%= peer.name %> \U1F638 ====== \n"
  <% if(!networkSettings.tls) { -%>
  docker exec -i cli.<%= org.domain %> bash -c \
    "source scripts/channel_fns.sh; fetchChannelAndJoin '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.address %>:7051' 'crypto/users/Admin@<%= org.domain %>/msp' '<%= rootOrg.ordererHead.address %>:7050';"
  <% } else { -%>
  docker exec -i cli.<%= org.domain %> bash -c \
    "source scripts/channel_fns.sh; fetchChannelAndJoinTls '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.address %>:7051' 'crypto/users/Admin@<%= org.domain %>/msp' 'crypto/users/Admin@<%= org.domain %>/tls' 'crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem' '<%= rootOrg.ordererHead.address %>:7050';"
  <% } %>
  <% } -%>
  <% } -%>
  <% } -%>
  <% }) -%>

  installChaincodes
  printf "============ \U1F984 Done! Enjoy your fresh network \U1F984 ============================= \n"
}

function networkDown() {
  printf "============ \U1F916 Stopping network \U1F916 =========================================== \n"
  cd fabric-compose
  docker-compose down
  cd ..

  printf "\nRemoving chaincode containers & images... \U1F5D1 \n"
   <% chaincodes.forEach(function(chaincode) {
     chaincode.channel.orgs.forEach(function (org) {
       org.peers.forEach(function (peer) {
        var chaincodeContainerName="dev-"+peer.address+"-"+chaincode.name+"-"+chaincode.version
  %>
  docker rm -f $(docker ps -a | grep <%= chaincodeContainerName %>-* | awk '{print $1}') || {
    echo "docker rm failed, Check if all fabric dockers properly was deleted"
  }
  docker rmi $(docker images <%= chaincodeContainerName %>-* -q) || {
    echo "docker rm failed, Check if all fabric dockers properly was deleted"
  }
  <% })})}) -%>

  printf "\nRemoving generated configs... \U1F5D1 \n"
  rm -rf fabric-config/config
  rm -rf fabric-config/crypto-config

  printf "============ \U1F5D1 Done! Network was purged \U1F5D1 =================================== \n"
}

function networkRerun() {
  networkDown
  networkUp
}

# TODO 1 - na koniec powinien polecieć anchorPeerUpdate
# TODO 2 - pomyśl o tym jak konfigurowac anchor peer'a
# TODO 3 - try/catch w bashu
