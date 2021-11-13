SCRIPT=$(readlink -f "$0")
BASEDIR=$(dirname "$SCRIPT")

function installChaincodes() {
  <% chaincodes.forEach(function(chaincode) {
     chaincode.channel.orgs.forEach(function (org) {
       org.peers.forEach(function (peer) {
  %>
  printf "============ \U1F60E Installing '<%= chaincode.name %>' on <%= chaincode.channel.name %>/<%= org.name %>/<%= peer.name %> \U1F60E ============== \n"
  <% if(!networkSettings.tls) { -%>
  chaincodeInstall "$BASEDIR/<%= chaincode.directory %>" "<%= chaincode.name %>" "<%= chaincode.version %>" "java" "<%= chaincode.channel.name %>" "<%= peer.address %>:7051" "<%= rootOrg.ordererHead.address %>:7050" "cli.<%= org.domain %>" # TODO to mi sie nie podoba. a gdzie uprawnienia ?
  <% } else { -%>
  chaincodeInstallTls "$BASEDIR/<%= chaincode.directory %>" "<%= chaincode.name %>" "<%= chaincode.version %>" "java" "<%= chaincode.channel.name %>" "<%= peer.address %>:7051" "<%= rootOrg.ordererHead.address %>:7050" "cli.<%= org.domain %>" "crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
  <% } -%>

  printf "==== \U1F618 Instantiating '<%= chaincode.name %>' on <%= chaincode.channel.name %>/<%= org.name %>/<%= peer.name %> \U1F618 ==== \n"
  <% if(!networkSettings.tls) { -%>
  chaincodeInstantiate "$BASEDIR/<%= chaincode.directory %>" "<%= chaincode.name %>" "<%= chaincode.version %>" "java" "<%= chaincode.channel.name %>" "<%= peer.address %>:7051" "<%= rootOrg.ordererHead.address %>:7050" "cli.<%= org.domain %>" '<%- chaincode.init %>' "<%- chaincode.endorsement %>"
  <% } else { -%>
  chaincodeInstantiateTls "$BASEDIR/<%= chaincode.directory %>" "<%= chaincode.name %>" "<%= chaincode.version %>" "java" "<%= chaincode.channel.name %>" "<%= peer.address %>:7051" "<%= rootOrg.ordererHead.address %>:7050" "cli.<%= org.domain %>" '<%- chaincode.init %>' "<%- chaincode.endorsement %>" "crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
  <% } -%>
  <% })})}) -%>

}

function generateArtifacts() {
  printf "============ \U1F913 Generating basic configs \U1F913 =================================== \n"
  printf "===== \U1F512 Generating crypto material for org <%= rootOrg.organization.name %> \U1F512 ===== \n"
  certsGenerate "$BASEDIR/fabric-config" "crypto-config-root.yaml" "ordererOrganizations/<%= rootOrg.organization.domain %>" "$BASEDIR/fabric-config/crypto-config/"
  <% orgs.forEach(function(org){  %>
  printf "===== \U1F512 Generating crypto material for <%= org.name %> \U1F512 ===== \n"
  certsGenerate "$BASEDIR/fabric-config" "<%= org.cryptoConfigFileName %>.yaml" "peerOrganizations/<%= org.domain %>" "$BASEDIR/fabric-config/crypto-config/"
  <% }) %>
  printf "===== \U1F3E0 Generating genesis block \U1F3E0 ===== \n"
  genesisBlockCreate "$BASEDIR/fabric-config" "$BASEDIR/fabric-config/config"
}

function startNetwork() {
  printf "============ \U1F680 Starting network \U1F680 =========================================== \n"
  CURRENT_DIR=$(pwd)
  cd "$BASEDIR"/fabric-compose
  docker-compose up -d
  cd $CURRENT_DIR
  sleep 4
}

function stopNetwork() {
  printf "============ \U1F68F Stopping network \U1F68F =========================================== \n"
  CURRENT_DIR=$(pwd)
  cd "$BASEDIR"/fabric-compose
  docker-compose stop
  cd $CURRENT_DIR
  sleep 4
}

function generateChannelsArtifacts() {
  <% channels.forEach(function(channel){  -%>
  printf "============ \U1F913 Generating config for '<%= channel.name %>' \U1F913 =========================== \n"
  createChannelTx "<%= channel.name %>" "$BASEDIR/fabric-config" "AllOrgChannel" "$BASEDIR/fabric-config/config"
  <% }) -%>
}

function installChannels() {
  <% channels.forEach(function(channel){  -%>

  <% for (orgNo in channel.orgs) {
      var org = channel.orgs[orgNo]
  -%>
  <% for (peerNo in org.peers) {
      var peer = org.peers[peerNo]
  -%>

  <% if(orgNo==0 && peerNo==0) { -%>
  printf "============ \U1F63B Creating '<%= channel.name %>' on <%= org.name %>/<%= peer.name %> \U1F63B ================== \n"
  <% if(!networkSettings.tls) { -%>
  docker exec -it cli.<%= org.domain %> bash -c \
    "source scripts/channel_fns.sh; createChannelAndJoin '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.address %>:7051' 'crypto/users/Admin@<%= org.domain %>/msp' '<%= rootOrg.ordererHead.address %>:7050';"
  <% } else { -%>
  docker exec -it cli.<%= org.domain %> bash -c \
    "source scripts/channel_fns.sh; createChannelAndJoinTls '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.address %>:7051' 'crypto/users/Admin@<%= org.domain %>/msp' 'crypto/users/Admin@<%= org.domain %>/tls' 'crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem' '<%= rootOrg.ordererHead.address %>:7050';"
  <% } %>
  <% } else { -%>
  printf "====== \U1F638 Joining '<%= channel.name %>' on  <%= org.name %>/<%= peer.name %> \U1F638 ====== \n"
  <% if(!networkSettings.tls) { -%>
  docker exec -it cli.<%= org.domain %> bash -c \
    "source scripts/channel_fns.sh; fetchChannelAndJoin '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.address %>:7051' 'crypto/users/Admin@<%= org.domain %>/msp' '<%= rootOrg.ordererHead.address %>:7050';"
  <% } else { -%>
  docker exec -it cli.<%= org.domain %> bash -c \
    "source scripts/channel_fns.sh; fetchChannelAndJoinTls '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.address %>:7051' 'crypto/users/Admin@<%= org.domain %>/msp' 'crypto/users/Admin@<%= org.domain %>/tls' 'crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem' '<%= rootOrg.ordererHead.address %>:7050';"
  <% } %>
  <% } -%>
  <% } -%>
  <% } -%>
  <% }) -%>

  printf "============ \U1F984 Done! Enjoy your fresh network \U1F984 ============================= \n"
}

function networkDown() {
  printf "============ \U1F916 Destroying network \U1F916 =========================================== \n"
  CURRENT_DIR=$(pwd)
  cd "$BASEDIR"/fabric-compose
  docker-compose down
  cd $CURRENT_DIR

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
  rm -rf $BASEDIR/fabric-config/config
  rm -rf $BASEDIR/fabric-config/crypto-config

  printf "============ \U1F5D1 Done! Network was purged \U1F5D1 =================================== \n"
}
