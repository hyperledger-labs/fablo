#!/bin/bash

function prepareChaincodeDirs() {
  <% if (!chaincodes || !chaincodes.length) { -%>
    echo "No chaincodes"
  <% } else { -%>
    <% chaincodes.forEach(function(chaincode) { %>
      mkdir -p "$CHAINCODES_BASE_DIR/<%= chaincode.directory %>"
    <% }) -%>
  <% } -%>
}

function installChaincodes() {
  <% if (!chaincodes || !chaincodes.length) { -%>
    echo "No chaincodes"
  <% } else { -%>
    <% chaincodes.forEach(function(chaincode) { -%>
      <%- include('commands-generated-node-build.sh.ejs', {chaincode: chaincode}); -%>
      <% chaincode.channel.orgs.forEach(function (org) {
           org.peers.forEach(function (peer) {
      %>
      printHeadline "Installing '<%= chaincode.name %>' on <%= chaincode.channel.name %>/<%= org.name %>/<%= peer.name %>" "U1F60E"
      <% if(!networkSettings.tls) { -%>
      chaincodeInstall "cli.<%= org.domain %>" "<%= peer.fullAddress %>" "<%= chaincode.channel.name %>" "<%= chaincode.name %>" "<%= chaincode.version %>" "<%= chaincode.lang %>" "$CHAINCODES_BASE_DIR/<%= chaincode.directory %>" "<%= rootOrg.ordererHead.fullAddress %>"
      <% } else { -%>
      chaincodeInstallTls "cli.<%= org.domain %>" "<%= peer.fullAddress %>" "<%= chaincode.channel.name %>" "<%= chaincode.name %>" "<%= chaincode.version %>" "<%= chaincode.lang %>" "$CHAINCODES_BASE_DIR/<%= chaincode.directory %>" "<%= rootOrg.ordererHead.fullAddress %>" "crypto/orderer-tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
      <% } -%>
      <% })}) -%>

      printItalics "Instantiating chaincode '<%= chaincode.name %>' on channel '<%= chaincode.channel.name %>' as '<%= chaincode.instantiatingOrg.name %>'" "U1F618"
      <% if(!networkSettings.tls) { -%>
      chaincodeInstantiate "cli.<%= chaincode.instantiatingOrg.domain %>" "<%= chaincode.instantiatingOrg.headPeer.fullAddress %>" "<%= chaincode.channel.name %>" "<%= chaincode.name %>" "<%= chaincode.version %>" "<%= chaincode.lang %>" "$CHAINCODES_BASE_DIR/<%= chaincode.directory %>" "<%= rootOrg.ordererHead.fullAddress %>" '<%- chaincode.init %>' "<%- chaincode.endorsement %>"
      <% } else { -%>
      chaincodeInstantiateTls "cli.<%= chaincode.instantiatingOrg.domain %>" "<%= chaincode.instantiatingOrg.headPeer.fullAddress %>" "<%= chaincode.channel.name %>" "<%= chaincode.name %>" "<%= chaincode.version %>" "<%= chaincode.lang %>" "$CHAINCODES_BASE_DIR/<%= chaincode.directory %>" "<%= rootOrg.ordererHead.fullAddress %>" '<%- chaincode.init %>' "<%- chaincode.endorsement %>" "crypto/orderer-tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
      <% } -%>
    <% }) %>
  <% } -%>
}

function upgradeChaincode() {
  chaincodeName="$1"
  version="$2"

  if [ -z "$chaincodeName" ]; then
    echo "Error: chaincode name is not provided"
    exit 1
  fi

  if [ -z "$version" ]; then
    echo "Error: chaincode version is not provided"
    exit 1
  fi

  <% chaincodes.forEach(function(chaincode) { %>
  if [ "$chaincodeName" = "<%= chaincode.name %>" ]; then
    <%- include('commands-generated-node-build.sh.ejs', {chaincode: chaincode}); -%>
    <% chaincode.channel.orgs.forEach(function (org) {
         org.peers.forEach(function (peer) {
    %>
    printHeadline "Installing '<%= chaincode.name %>' on <%= chaincode.channel.name %>/<%= org.name %>/<%= peer.name %>" "U1F60E"
    <% if(!networkSettings.tls) { -%>
    chaincodeInstall "cli.<%= org.domain %>" "<%= peer.fullAddress %>" "<%= chaincode.channel.name %>" "<%= chaincode.name %>" "$version" "<%= chaincode.lang %>" "$CHAINCODES_BASE_DIR/<%= chaincode.directory %>" "<%= rootOrg.ordererHead.fullAddress %>"
    <% } else { -%>
    chaincodeInstallTls "cli.<%= org.domain %>" "<%= peer.fullAddress %>" "<%= chaincode.channel.name %>" "<%= chaincode.name %>" "$version" "<%= chaincode.lang %>" "$CHAINCODES_BASE_DIR/<%= chaincode.directory %>" "<%= rootOrg.ordererHead.fullAddress %>" "crypto/orderer-tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
    <% } -%>
    <% })}) -%>

    printItalics "Upgrading as '<%= chaincode.instantiatingOrg.name %>'. '<%= chaincode.name %>' on channel '<%= chaincode.channel.name %>'" "U1F618"
    <% if(!networkSettings.tls) { -%>
    chaincodeUpgrade "cli.<%= chaincode.instantiatingOrg.domain %>" "<%=  chaincode.instantiatingOrg.headPeer.fullAddress %>" "<%= chaincode.channel.name %>" "<%= chaincode.name %>" "$version" "<%= chaincode.lang %>" "$CHAINCODES_BASE_DIR/<%= chaincode.directory %>" "<%= rootOrg.ordererHead.fullAddress %>" '<%- chaincode.init %>' "<%- chaincode.endorsement %>"
    <% } else { -%>
    chaincodeUpgradeTls "cli.<%= chaincode.instantiatingOrg.domain %>" "<%=  chaincode.instantiatingOrg.headPeer.fullAddress %>" "<%= chaincode.channel.name %>" "<%= chaincode.name %>" "$version" "<%= chaincode.lang %>" "$CHAINCODES_BASE_DIR/<%= chaincode.directory %>" "<%= rootOrg.ordererHead.fullAddress %>" '<%- chaincode.init %>' "<%- chaincode.endorsement %>" "crypto/orderer-tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
    <% } %>
  fi
  <% }) %>
}

function notifyOrgsAboutChannels() {
  printHeadline "Creating new channel config blocks" "U1F537"
  <% channels.forEach(function(channel){  channel.orgs.forEach(function(org){ -%>
createNewChannelUpdateTx "<%= channel.name %>" "<%= org.mspName %>" "AllOrgChannel" "$FABRICA_NETWORK_ROOT/fabric-config"  "$FABRICA_NETWORK_ROOT/fabric-config/config"
  <% })}) %>
  printHeadline "Notyfing orgs about channels" "U1F4E2"
  <% channels.forEach(function(channel){  channel.orgs.forEach(function(org){ -%>
  <% if(!networkSettings.tls) { -%>
notifyOrgAboutNewChannel "<%= channel.name %>" "<%= org.mspName %>" "cli.<%= org.domain %>" "peer0.<%= org.domain %>" "<%= rootOrg.ordererHead.fullAddress %>"
  <% } else { -%>
notifyOrgAboutNewChannelTls "<%= channel.name %>" "<%= org.mspName %>" "cli.<%= org.domain %>" "peer0.<%= org.domain %>" "<%= rootOrg.ordererHead.fullAddress %>" "crypto/orderer-tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem"
  <% } -%>
  <% })}) %>
  printHeadline "Deleting new channel config blocks" "U1F52A"
    <% channels.forEach(function(channel){  channel.orgs.forEach(function(org){ -%>
deleteNewChannelUpdateTx "<%= channel.name %>" "<%= org.mspName %>" "cli.<%= org.domain %>"
  <% })}) %>
}

function generateArtifacts() {
  printHeadline "Generating basic configs" "U1F913"
  printItalics "Generating crypto material for org <%= rootOrg.organization.name %>" "U1F512"
  certsGenerate "$FABRICA_NETWORK_ROOT/fabric-config" "crypto-config-root.yaml" "ordererOrganizations/<%= rootOrg.organization.domain %>" "$FABRICA_NETWORK_ROOT/fabric-config/crypto-config/"
  <% orgs.forEach(function(org){  %>
  printItalics "Generating crypto material for <%= org.name %>" "U1F512"
  certsGenerate "$FABRICA_NETWORK_ROOT/fabric-config" "<%= org.cryptoConfigFileName %>.yaml" "peerOrganizations/<%= org.domain %>" "$FABRICA_NETWORK_ROOT/fabric-config/crypto-config/"
  <% }) %>
  printItalics "Generating genesis block" "U1F3E0"
  genesisBlockCreate "$FABRICA_NETWORK_ROOT/fabric-config" "$FABRICA_NETWORK_ROOT/fabric-config/config"
}

function startNetwork() {
  printHeadline "Starting network" "U1F680"
  (
    cd "$FABRICA_NETWORK_ROOT"/fabric-docker
    docker-compose up -d
    sleep 4
  )
}

function stopNetwork() {
  printHeadline "Stopping network" "U1F68F"
  (
    cd "$FABRICA_NETWORK_ROOT"/fabric-docker
    docker-compose stop
    sleep 4
  )
}

function generateChannelsArtifacts() {
  <% channels.forEach(function(channel){  -%>
  printHeadline "Generating config for '<%= channel.name %>'" "U1F913"
  createChannelTx "<%= channel.name %>" "$FABRICA_NETWORK_ROOT/fabric-config" "AllOrgChannel" "$FABRICA_NETWORK_ROOT/fabric-config/config"
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
    "source scripts/channel_fns.sh; createChannelAndJoin '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.fullAddress %>' 'crypto/users/Admin@<%= org.domain %>/msp' '<%= rootOrg.ordererHead.fullAddress %>';"
  <% } else { -%>
  docker exec -i cli.<%= org.domain %> bash -c \
    "source scripts/channel_fns.sh; createChannelAndJoinTls '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.fullAddress %>' 'crypto/users/Admin@<%= org.domain %>/msp' 'crypto/users/Admin@<%= org.domain %>/tls' 'crypto/orderer-tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem' '<%= rootOrg.ordererHead.fullAddress %>';"
  <% } %>
  <% } else { -%>
  printItalics "Joining '<%= channel.name %>' on  <%= org.name %>/<%= peer.name %>" "U1F638"
  <% if(!networkSettings.tls) { -%>
  docker exec -i cli.<%= org.domain %> bash -c \
    "source scripts/channel_fns.sh; fetchChannelAndJoin '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.fullAddress %>' 'crypto/users/Admin@<%= org.domain %>/msp' '<%= rootOrg.ordererHead.fullAddress %>';"
  <% } else { -%>
  docker exec -i cli.<%= org.domain %> bash -c \
    "source scripts/channel_fns.sh; fetchChannelAndJoinTls '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.fullAddress %>' 'crypto/users/Admin@<%= org.domain %>/msp' 'crypto/users/Admin@<%= org.domain %>/tls' 'crypto/orderer-tlscacerts/tlsca.<%= rootOrg.organization.domain %>-cert.pem' '<%= rootOrg.ordererHead.fullAddress %>';"
  <% } %>
  <% } -%>
  <% } -%>
  <% } -%>
  <% }) -%>
}

function networkDown() {
  printHeadline "Destroying network" "U1F916"
  (
    cd "$FABRICA_NETWORK_ROOT"/fabric-docker
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
  rm -rf "$FABRICA_NETWORK_ROOT"/fabric-config/config
  rm -rf "$FABRICA_NETWORK_ROOT"/fabric-config/crypto-config

  printHeadline "Done! Network was purged" "U1F5D1"
}
