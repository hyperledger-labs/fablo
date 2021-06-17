#!/usr/bin/env bash

function installChaincodes() {
  <% if (!chaincodes || !chaincodes.length) { -%>
    echo "No chaincodes"
  <% } else { -%>
    <% chaincodes.forEach(function(chaincode) { -%>
      if [ -n "$(ls "$CHAINCODES_BASE_DIR/<%= chaincode.directory %>")" ]; then
        <% if (capabilities.isV2) { -%>
          local version="<%= chaincode.version %>"
          <%- include('commands-generated/chaincode-install-v2.sh', { chaincode, rootOrg, networkSettings }); -%>
        <% } else { -%>
          <%- include('commands-generated/chaincode-install-v1.4.sh', { chaincode, rootOrg, networkSettings }); -%>
        <% } -%>
      else
        echo "Warning! Skipping chaincode '<%= chaincode.name %>' installation. Chaincode directory is empty."
        echo "Looked in dir: '$CHAINCODES_BASE_DIR/<%= chaincode.directory %>'"
      fi
    <% }) %>
  <% } -%>
}

function upgradeChaincode() {
  local chaincodeName="$1"
  if [ -z "$chaincodeName" ]; then echo "Error: chaincode name is not provided"; exit 1; fi

  local version="$2"
  if [ -z "$version" ]; then echo "Error: chaincode version is not provided"; exit 1; fi

  <% chaincodes.forEach(function(chaincode) { -%>
    if [ "$chaincodeName" = "<%= chaincode.name %>" ]; then
      if [ -n "$(ls "$CHAINCODES_BASE_DIR/<%= chaincode.directory %>")" ]; then
        <% if (capabilities.isV2) { -%>
          <%- include('commands-generated/chaincode-install-v2.sh', { chaincode, rootOrg, networkSettings }); %>
        <% } else { -%>
          <%- include('commands-generated/chaincode-upgrade-v1.4.sh', { chaincode, rootOrg, networkSettings }); %>
        <% } -%>
      else
        echo "Warning! Skipping chaincode '<%= chaincode.name %>' upgrade. Chaincode directory is empty."
        echo "Looked in dir: '$CHAINCODES_BASE_DIR/<%= chaincode.directory %>'"
      fi
    fi
  <% }) -%>
}

function notifyOrgsAboutChannels() {
  printHeadline "Creating new channel config blocks" "U1F537"
  <% channels.forEach(function(channel){ -%>
    <% channel.orgs.forEach(function(org){ -%>
      createNewChannelUpdateTx <% -%>
        "<%= channel.name %>" <% -%>
        "<%= org.mspName %>" <% -%>
        "<%= channel.profile.name %>" <% -%>
        "$FABRICA_NETWORK_ROOT/fabric-config" <% -%>
        "$FABRICA_NETWORK_ROOT/fabric-config/config"
    <% }) -%>
  <% }) %>

  printHeadline "Notyfing orgs about channels" "U1F4E2"
  <% channels.forEach(function(channel){ -%>
    <% channel.orgs.forEach(function(org){ -%>
     <% if(!networkSettings.tls) { -%>
       notifyOrgAboutNewChannel <% -%>
         "<%= channel.name %>" <% -%>
         "<%= org.mspName %>" <% -%>
         "<%= org.cli.address %>" <% -%>
         "peer0.<%= org.domain %>" <% -%>
         "<%= rootOrg.ordererHead.fullAddress %>"
     <% } else { -%>
       notifyOrgAboutNewChannelTls <% -%>
         "<%= channel.name %>" <% -%>
         "<%= org.mspName %>" <% -%>
         "<%= org.cli.address %>" <% -%>
         "peer0.<%= org.domain %>" <% -%>
         "<%= rootOrg.ordererHead.fullAddress %>" <% -%>
         "crypto-orderer/tlsca.<%= rootOrg.domain %>-cert.pem"
     <% } -%>
    <% }) -%>
  <% }) %>

  printHeadline "Deleting new channel config blocks" "U1F52A"
  <% channels.forEach(function(channel){ -%>
    <% channel.orgs.forEach(function(org){ -%>
      deleteNewChannelUpdateTx "<%= channel.name %>" "<%= org.mspName %>" "<%= org.cli.address %>"
    <% }) -%>
  <% }) -%>
}

function generateArtifacts() {
  printHeadline "Generating basic configs" "U1F913"
  printItalics "Generating crypto material for org <%= rootOrg.name %>" "U1F512"
  certsGenerate <% -%>
    "$FABRICA_NETWORK_ROOT/fabric-config" <% -%>
    "crypto-config-root.yaml" <% -%>
    "ordererOrganizations/<%= rootOrg.domain %>" <% -%>
    "$FABRICA_NETWORK_ROOT/fabric-config/crypto-config/"

  <% orgs.forEach(function(org){ -%>
    printItalics "Generating crypto material for <%= org.name %>" "U1F512"
    certsGenerate <% -%>
      "$FABRICA_NETWORK_ROOT/fabric-config" <% -%>
      "<%= org.cryptoConfigFileName %>.yaml" <% -%>
      "peerOrganizations/<%= org.domain %>" <% -%>
      "$FABRICA_NETWORK_ROOT/fabric-config/crypto-config/"
  <% }) -%>

  printItalics "Generating genesis block" "U1F3E0"
  genesisBlockCreate "$FABRICA_NETWORK_ROOT/fabric-config" "$FABRICA_NETWORK_ROOT/fabric-config/config"

  # Create directory for chaincode packages to avoid permission errors on linux
  mkdir -p "$FABRICA_NETWORK_ROOT/fabric-config/chaincode-packages"
}

function startNetwork() {
  printHeadline "Starting network" "U1F680"
  (cd "$FABRICA_NETWORK_ROOT"/fabric-docker && docker-compose up -d)
  sleep 4
}

function stopNetwork() {
  printHeadline "Stopping network" "U1F68F"
  (cd "$FABRICA_NETWORK_ROOT"/fabric-docker && docker-compose stop)
  sleep 4
}

function generateChannelsArtifacts() {
  <% if (!channels || !channels.length) { -%>
    echo "No channels"
  <% } else { -%>
    <% channels.forEach(function(channel){  -%>
      printHeadline "Generating config for '<%= channel.name %>'" "U1F913"
      createChannelTx "<%= channel.name %>" "$FABRICA_NETWORK_ROOT/fabric-config" "<%= channel.profile.name %>" "$FABRICA_NETWORK_ROOT/fabric-config/config"
    <% }) -%>
  <% } -%>
}

function installChannels() {
  <% if (!channels || !channels.length) { -%>
    echo "No channels"
  <% } else { -%>
    <% channels.forEach(function(channel){ -%>
      <% channel.orgs.forEach(function(org, orgNo){ -%>
        <% org.peers.forEach(function(peer, peerNo){ -%>
          <% if(orgNo == 0 && peerNo == 0) { -%>
            printHeadline "Creating '<%= channel.name %>' on <%= org.name %>/<%= peer.name %>" "U1F63B"
            <% if(!networkSettings.tls) { -%>
              docker exec -i <%= org.cli.address %> bash -c <% -%>
                "source scripts/channel_fns.sh; createChannelAndJoin '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.fullAddress %>' 'crypto/users/Admin@<%= org.domain %>/msp' '<%= rootOrg.ordererHead.fullAddress %>';"
            <% } else { -%>
              docker exec -i <%= org.cli.address %> bash -c <% -%>
                "source scripts/channel_fns.sh; createChannelAndJoinTls '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.fullAddress %>' 'crypto/users/Admin@<%= org.domain %>/msp' 'crypto/users/Admin@<%= org.domain %>/tls' 'crypto-orderer/tlsca.<%= rootOrg.domain %>-cert.pem' '<%= rootOrg.ordererHead.fullAddress %>';"
            <% } %>
          <% } else { -%>
            printItalics "Joining '<%= channel.name %>' on  <%= org.name %>/<%= peer.name %>" "U1F638"
            <% if(!networkSettings.tls) { -%>
              docker exec -i <%= org.cli.address %> bash -c <% -%>
                "source scripts/channel_fns.sh; fetchChannelAndJoin '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.fullAddress %>' 'crypto/users/Admin@<%= org.domain %>/msp' '<%= rootOrg.ordererHead.fullAddress %>';"
            <% } else { -%>
              docker exec -i <%= org.cli.address %> bash -c <% -%>
                "source scripts/channel_fns.sh; fetchChannelAndJoinTls '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.fullAddress %>' 'crypto/users/Admin@<%= org.domain %>/msp' 'crypto/users/Admin@<%= org.domain %>/tls' 'crypto-orderer/tlsca.<%= rootOrg.domain %>-cert.pem' '<%= rootOrg.ordererHead.fullAddress %>';"
            <% } -%>
          <% } -%>
        <% }) -%>
      <% }) -%>
    <% }) -%>
  <% } -%>
}

function networkDown() {
  printHeadline "Destroying network" "U1F916"
  (cd "$FABRICA_NETWORK_ROOT"/fabric-docker && docker-compose down)

  printf "\nRemoving chaincode containers & images... \U1F5D1 \n"
  <% chaincodes.forEach(function(chaincode) { -%>
    <% chaincode.channel.orgs.forEach(function (org) { -%>
      <% org.peers.forEach(function (peer) { -%>
        <% const chaincodeContainerName=`dev-${peer.address}-${chaincode.name}-${chaincode.version}` -%>
        docker rm -f $(docker ps -a | grep <%= chaincodeContainerName %>-* | awk '{print $1}') || echo "docker rm failed, Check if all fabric dockers properly was deleted"
        docker rmi $(docker images <%= chaincodeContainerName %>-* -q) || echo "docker rm failed, Check if all fabric dockers properly was deleted"
      <% }) -%>
    <% }) -%>
  <% }) -%>

  printf "\nRemoving generated configs... \U1F5D1 \n"
  rm -rf "$FABRICA_NETWORK_ROOT/fabric-config/config"
  rm -rf "$FABRICA_NETWORK_ROOT/fabric-config/crypto-config"
  rm -rf "$FABRICA_NETWORK_ROOT/fabric-config/chaincode-packages"

  printHeadline "Done! Network was purged" "U1F5D1"
}
