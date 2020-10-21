#!/bin/bash

function installChaincodes() {
  <% chaincodes.forEach(function(chaincode) { %>
  <%- include('commands-generated-node-build.sh.ejs', {chaincode: chaincode}); -%>
  <% chaincode.channel.orgs.forEach(function (org) {
       org.peers.forEach(function (peer) {
  %>
  printHeadline "Installing '<%= chaincode.name %>' on <%= chaincode.channel.name %>/<%= org.name %>/<%= peer.name %>" "U1F60E"
  <% if(!networkSettings.tls) { -%>
  chaincodeInstall "$FABRIKKA_CHAINCODES_ROOT/<%= chaincode.directory %>" "<%= chaincode.name %>" "<%= chaincode.version %>" "<%= chaincode.lang %>" "<%= chaincode.channel.name %>" "<%= peer.address %>:7051" "<%= rootOrg.ordererHead.address %>:7050" "cli.<%= org.domain %>" # TODO to mi sie nie podoba. a gdzie uprawnienia ?
  <% } else { -%>
  chaincodeInstallTls "$FABRIKKA_CHAINCODES_ROOT/<%= chaincode.directory %>" "<%= chaincode.name %>" "<%= chaincode.version %>" "<%= chaincode.lang %>" "<%= chaincode.channel.name %>" "<%= peer.address %>:7051" "<%= rootOrg.ordererHead.address %>:7050" "cli.<%= org.domain %>" "crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
  <% } -%>

  printItalics "Instantiating '<%= chaincode.name %>' on <%= chaincode.channel.name %>/<%= org.name %>/<%= peer.name %>" "U1F618"
  <% if(!networkSettings.tls) { -%>
  chaincodeInstantiate "$FABRIKKA_CHAINCODES_ROOT/<%= chaincode.directory %>" "<%= chaincode.name %>" "<%= chaincode.version %>" "<%= chaincode.lang %>" "<%= chaincode.channel.name %>" "<%= peer.address %>:7051" "<%= rootOrg.ordererHead.address %>:7050" "cli.<%= org.domain %>" '<%- chaincode.init %>' "<%- chaincode.endorsement %>"
  <% } else { -%>
  chaincodeInstantiateTls "$FABRIKKA_CHAINCODES_ROOT/<%= chaincode.directory %>" "<%= chaincode.name %>" "<%= chaincode.version %>" "<%= chaincode.lang %>" "<%= chaincode.channel.name %>" "<%= peer.address %>:7051" "<%= rootOrg.ordererHead.address %>:7050" "cli.<%= org.domain %>" '<%- chaincode.init %>' "<%- chaincode.endorsement %>" "crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
  <% } -%>
  <% })})}) -%>

}

function notifyOrgsAboutChannels() {
  printHeadline "Creating new channel config blocks" "U1F537"
  <% channels.forEach(function(channel){  channel.orgs.forEach(function(org){ -%>
createNewChannelUpdateTx "<%= channel.name %>" "<%= org.mspName %>" "AllOrgChannel" "$BASEDIR/fabric-config"  "$BASEDIR/fabric-config/config"
  <% })}) %>
  printHeadline "Notyfing orgs about channels" "U1F4E2"
  <% channels.forEach(function(channel){  channel.orgs.forEach(function(org){ -%>
  <% if(!networkSettings.tls) { -%>
notifyOrgAboutNewChannel "<%= channel.name %>" "<%= org.mspName %>" "cli.<%= org.domain %>" "peer0.<%= org.domain %>" "<%= rootOrg.ordererHead.address %>:7050"
  <% } else { -%>
notifyOrgAboutNewChannelTls "<%= channel.name %>" "<%= org.mspName %>" "cli.<%= org.domain %>" "peer0.<%= org.domain %>" "<%= rootOrg.ordererHead.address %>:7050" "crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
  <% } -%>
  <% })}) %>
  printHeadline "Creating new channel config blocks" "U1F52A"
    <% channels.forEach(function(channel){  channel.orgs.forEach(function(org){ -%>
deleteNewChannelUpdateTx "<%= channel.name %>" "<%= org.mspName %>" "cli.<%= org.domain %>"
  <% })}) %>
}

function generateArtifacts() {
  printHeadline "Generating basic configs" "U1F913"
  printItalics "Generating crypto material for org <%= rootOrg.organization.name %>" "U1F512"
  certsGenerate "$FABRIKKA_DOCKER_ROOT/fabric-config" "crypto-config-root.yaml" "ordererOrganizations/<%= rootOrg.organization.domain %>" "$FABRIKKA_DOCKER_ROOT/fabric-config/crypto-config/"
  <% orgs.forEach(function(org){  %>
  printItalics "Generating crypto material for <%= org.name %>" "U1F512"
  certsGenerate "$FABRIKKA_DOCKER_ROOT/fabric-config" "<%= org.cryptoConfigFileName %>.yaml" "peerOrganizations/<%= org.domain %>" "$FABRIKKA_DOCKER_ROOT/fabric-config/crypto-config/"
  <% }) %>
  printItalics "Generating genesis block" "U1F3E0"
  genesisBlockCreate "$FABRIKKA_DOCKER_ROOT/fabric-config" "$FABRIKKA_DOCKER_ROOT/fabric-config/config"
}

function startNetwork() {
  printHeadline "Starting network" "U1F680"
  (
    cd "$FABRIKKA_DOCKER_ROOT"/fabric-docker
    docker-compose up -d
    sleep 4
  )
}

function stopNetwork() {
  printHeadline "Stopping network" "U1F68F"
  (
    cd "$FABRIKKA_DOCKER_ROOT"/fabric-docker
    docker-compose stop
    sleep 4
  )
}

function generateChannelsArtifacts() {
  <% channels.forEach(function(channel){  -%>
  printHeadline "Generating config for '<%= channel.name %>'" "U1F913"
  createChannelTx "<%= channel.name %>" "$FABRIKKA_DOCKER_ROOT/fabric-config" "AllOrgChannel" "$FABRIKKA_DOCKER_ROOT/fabric-config/config"
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
  printHeadline "Creating '<%= channel.name %>' on <%= org.name %>/<%= peer.name %>" "U1F63B"
  <% if(!networkSettings.tls) { -%>
  docker exec -i cli.<%= org.domain %> bash -c \
    "source scripts/channel_fns.sh; createChannelAndJoin '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.address %>:7051' 'crypto/users/Admin@<%= org.domain %>/msp' '<%= rootOrg.ordererHead.address %>:7050';"
  <% } else { -%>
  docker exec -i cli.<%= org.domain %> bash -c \
    "source scripts/channel_fns.sh; createChannelAndJoinTls '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.address %>:7051' 'crypto/users/Admin@<%= org.domain %>/msp' 'crypto/users/Admin@<%= org.domain %>/tls' 'crypto/daTls/msp/tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem' '<%= rootOrg.ordererHead.address %>:7050';"
  <% } %>
  <% } else { -%>
  printItalics "Joining '<%= channel.name %>' on  <%= org.name %>/<%= peer.name %>" "U1F638"
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
}

function networkDown() {
  printHeadline "Destroying network" "U1F916"
  (
    cd "$FABRIKKA_DOCKER_ROOT"/fabric-docker
    docker-compose down
  )

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
  rm -rf $FABRIKKA_DOCKER_ROOT/fabric-config/config
  rm -rf $FABRIKKA_DOCKER_ROOT/fabric-config/crypto-config

  printHeadline "Done! Network was purged" "U1F5D1"
}
