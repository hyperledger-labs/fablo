#!/usr/bin/env bash

generateArtifacts() {
  printHeadline "Generating basic configs" "U1F913"

  <% orgs.forEach((org) => { -%>
    printItalics "Generating crypto material for <%= org.name %>" "U1F512"
    certsGenerate <% -%>
      "$FABLO_NETWORK_ROOT/fabric-config" <% -%>
      "<%= org.cryptoConfigFileName %>.yaml" <% -%>
      "peerOrganizations/<%= org.domain %>" <% -%>
      "$FABLO_NETWORK_ROOT/fabric-config/crypto-config/"

  <% }) -%>
  <%_ ordererGroups.forEach((ordererGroup) => { _%>
  printItalics "Generating genesis block for group <%= ordererGroup.name %>" "U1F3E0"
  genesisBlockCreate "$FABLO_NETWORK_ROOT/fabric-config" "$FABLO_NETWORK_ROOT/fabric-config/config" "<%= ordererGroup.profileName %>"

  <%_ }) _%>
  # Create directory for chaincode packages to avoid permission errors on linux
  mkdir -p "$FABLO_NETWORK_ROOT/fabric-config/chaincode-packages"
}

startNetwork() {
  printHeadline "Starting network" "U1F680"
  (cd "$FABLO_NETWORK_ROOT"/fabric-docker && docker-compose up -d)
  sleep 4
}

generateChannelsArtifacts() {
  <% if (!channels || !channels.length) { -%>
    echo "No channels"
  <% } else { -%>
    <% channels.forEach((channel) => {  -%>
      printHeadline "Generating config for '<%= channel.name %>'" "U1F913"
      createChannelTx "<%= channel.name %>" "$FABLO_NETWORK_ROOT/fabric-config" "<%= channel.profileName %>" "$FABLO_NETWORK_ROOT/fabric-config/config"
    <% }) -%>
  <% } -%>
}

installChannels() {
  <% if (!channels || !channels.length) { -%>
    echo "No channels"
  <% } else { -%>
    <% channels.forEach((channel) => { -%>
      <% channel.orgs.forEach((org, orgNo) => { -%>
        <% org.peers.forEach((peer, peerNo) => { -%>
          <% if(orgNo == 0 && peerNo == 0) { -%>
            printHeadline "Creating '<%= channel.name %>' on <%= org.name %>/<%= peer.name %>" "U1F63B"
            <% if(!global.tls) { -%>
              docker exec -i <%= org.cli.address %> bash -c <% -%>
                "source scripts/channel_fns.sh; createChannelAndJoin '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.fullAddress %>' 'crypto/users/Admin@<%= org.domain %>/msp' '<%= channel.ordererHead.fullAddress %>';"
            <% } else { -%>
              docker exec -i <%= org.cli.address %> bash -c <% -%>
                "source scripts/channel_fns.sh; createChannelAndJoinTls '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.fullAddress %>' 'crypto/users/Admin@<%= org.domain %>/msp' 'crypto/users/Admin@<%= org.domain %>/tls' 'crypto-orderer/tlsca.<%= channel.ordererHead.domain %>-cert.pem' '<%= channel.ordererHead.fullAddress %>';"
            <% } %>
          <% } else { -%>
            printItalics "Joining '<%= channel.name %>' on  <%= org.name %>/<%= peer.name %>" "U1F638"
            <% if(!global.tls) { -%>
              docker exec -i <%= org.cli.address %> bash -c <% -%>
                "source scripts/channel_fns.sh; fetchChannelAndJoin '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.fullAddress %>' 'crypto/users/Admin@<%= org.domain %>/msp' '<%= channel.ordererHead.fullAddress %>';"
            <% } else { -%>
              docker exec -i <%= org.cli.address %> bash -c <% -%>
                "source scripts/channel_fns.sh; fetchChannelAndJoinTls '<%= channel.name %>' '<%= org.mspName %>' '<%= peer.fullAddress %>' 'crypto/users/Admin@<%= org.domain %>/msp' 'crypto/users/Admin@<%= org.domain %>/tls' 'crypto-orderer/tlsca.<%= channel.ordererHead.domain %>-cert.pem' '<%= channel.ordererHead.fullAddress %>';"
            <% } -%>
          <% } -%>
        <% }) -%>
      <% }) -%>
    <% }) -%>
  <% } -%>
}

installChaincodes() {
  <% if (!chaincodes || !chaincodes.length) { -%>
    echo "No chaincodes"
  <% } else { -%>
    <% chaincodes.forEach((chaincode) => { -%>
      if [ -n "$(ls "$CHAINCODES_BASE_DIR/<%= chaincode.directory %>")" ]; then
        <% if (global.capabilities.isV2) { -%>
          <% if (global.peerDevMode) { -%>
            <%- include('commands-generated/chaincode-dev-v2.sh', { chaincode }); -%>
          <% } else { -%>
            local version="<%= chaincode.version %>"
            <%- include('commands-generated/chaincode-install-v2.sh', { chaincode, global }); -%>
          <% } -%>
        <% } else { -%>
          <%- include('commands-generated/chaincode-install-v1.4.sh', { chaincode, global }); -%>
        <% } -%>
      else
        echo "Warning! Skipping chaincode '<%= chaincode.name %>' installation. Chaincode directory is empty."
        echo "Looked in dir: '$CHAINCODES_BASE_DIR/<%= chaincode.directory %>'"
      fi
    <% }) %>
  <% } -%>
}

installChaincode() {
  local chaincodeName="$1"
  if [ -z "$chaincodeName" ]; then echo "Error: chaincode name is not provided"; exit 1; fi

  local version="$2"
  if [ -z "$version" ]; then echo "Error: chaincode version is not provided"; exit 1; fi

  <% chaincodes.forEach((chaincode) => { -%>
    if [ "$chaincodeName" = "<%= chaincode.name %>" ]; then
      if [ -n "$(ls "$CHAINCODES_BASE_DIR/<%= chaincode.directory %>")" ]; then
        <% if (global.capabilities.isV2) { -%>
          <%- include('commands-generated/chaincode-install-v2.sh', { chaincode, global }); %>
        <% } else { -%>
          <%- include('commands-generated/chaincode-install-v1.4.sh', { chaincode, global }); %>
        <% } -%>
      else
        echo "Warning! Skipping chaincode '<%= chaincode.name %>' install. Chaincode directory is empty."
        echo "Looked in dir: '$CHAINCODES_BASE_DIR/<%= chaincode.directory %>'"
      fi
    fi
  <% }) -%>
}

runDevModeChaincode() {
  <% if (!global.capabilities.isV2) { -%>
    echo "Running chaincode in dev mode is supported by Fablo only for V2 channel capabilities"
    exit 1
  <% } else { -%>
    local chaincodeName=$1
    if [ -z "$chaincodeName" ]; then echo "Error: chaincode name is not provided"; exit 1; fi

    <% chaincodes.forEach((chaincode) => { -%>
      if [ "$chaincodeName" = "<%= chaincode.name %>" ]; then
        local version="<%= chaincode.version %>"
        <%- include('commands-generated/chaincode-dev-v2.sh', { chaincode, global }); %>
      fi
    <% }) -%>
  <% } -%>
}

upgradeChaincode() {
  local chaincodeName="$1"
  if [ -z "$chaincodeName" ]; then echo "Error: chaincode name is not provided"; exit 1; fi

  local version="$2"
  if [ -z "$version" ]; then echo "Error: chaincode version is not provided"; exit 1; fi

  <% chaincodes.forEach((chaincode) => { -%>
    if [ "$chaincodeName" = "<%= chaincode.name %>" ]; then
      if [ -n "$(ls "$CHAINCODES_BASE_DIR/<%= chaincode.directory %>")" ]; then
        <% if (global.capabilities.isV2) { -%>
          <%- include('commands-generated/chaincode-install-v2.sh', { chaincode, global }); %>
        <% } else { -%>
          <%- include('commands-generated/chaincode-upgrade-v1.4.sh', { chaincode, global }); %>
        <% } -%>
      else
        echo "Warning! Skipping chaincode '<%= chaincode.name %>' upgrade. Chaincode directory is empty."
        echo "Looked in dir: '$CHAINCODES_BASE_DIR/<%= chaincode.directory %>'"
      fi
    fi
  <% }) -%>
}

notifyOrgsAboutChannels() {
  printHeadline "Creating new channel config blocks" "U1F537"
  <% channels.forEach((channel) => { -%>
    <% channel.orgs.forEach((org) => { -%>
      createNewChannelUpdateTx <% -%>
        "<%= channel.name %>" <% -%>
        "<%= org.mspName %>" <% -%>
        "<%= channel.profileName %>" <% -%>
        "$FABLO_NETWORK_ROOT/fabric-config" <% -%>
        "$FABLO_NETWORK_ROOT/fabric-config/config"
    <% }) -%>
  <% }) %>

  printHeadline "Notyfing orgs about channels" "U1F4E2"
  <% channels.forEach((channel) => { -%>
    <% channel.orgs.forEach((org) => { -%>
     <% if(!global.tls) { -%>
       notifyOrgAboutNewChannel <% -%>
         "<%= channel.name %>" <% -%>
         "<%= org.mspName %>" <% -%>
         "<%= org.cli.address %>" <% -%>
         "peer0.<%= org.domain %>" <% -%>
         "<%= channel.ordererHead.fullAddress %>"
     <% } else { -%>
       notifyOrgAboutNewChannelTls <% -%>
         "<%= channel.name %>" <% -%>
         "<%= org.mspName %>" <% -%>
         "<%= org.cli.address %>" <% -%>
         "peer0.<%= org.domain %>" <% -%>
         "<%= channel.ordererHead.fullAddress %>" <% -%>
         "crypto-orderer/tlsca.<%= channel.ordererHead.domain %>-cert.pem"
     <% } -%>
    <% }) -%>
  <% }) %>

  printHeadline "Deleting new channel config blocks" "U1F52A"
  <% channels.forEach((channel) => { -%>
    <% channel.orgs.forEach((org) => { -%>
      deleteNewChannelUpdateTx "<%= channel.name %>" "<%= org.mspName %>" "<%= org.cli.address %>"
    <% }) -%>
  <% }) -%>
}

printStartSuccessInfo() {
  printHeadline "Done! Enjoy your fresh network" "U1F984"
  <% if (global.peerDevMode) { -%>
    echo "It has peerDevMode enabled, so remember to start your chaincodes manually."
  <% } -%>
}

stopNetwork() {
  printHeadline "Stopping network" "U1F68F"
  (cd "$FABLO_NETWORK_ROOT"/fabric-docker && docker-compose stop)
  sleep 4
}

networkDown() {
  printHeadline "Destroying network" "U1F916"
  (cd "$FABLO_NETWORK_ROOT"/fabric-docker && docker-compose down)

  printf "\nRemoving chaincode containers & images... \U1F5D1 \n"
  <% chaincodes.forEach((chaincode) => { -%>
    <% chaincode.channel.orgs.forEach((org) => { -%>
      <% org.peers.forEach((peer) => { -%>
        <% const chaincodeContainerName=`dev-${peer.address}-${chaincode.name}` -%>
        for container in $(docker ps -a | grep "<%= chaincodeContainerName %>" | awk '{print $1}'); do echo "Removing container $container..."; docker rm -f "$container" || echo "docker rm of $container failed. Check if all fabric dockers properly was deleted"; done
        for image in $(docker images "<%= chaincodeContainerName %>*" -q); do echo "Removing image $image..."; docker rmi "$image" || echo "docker rmi of $image failed. Check if all fabric dockers properly was deleted"; done
      <% }) -%>
    <% }) -%>
  <% }) -%>

  printf "\nRemoving generated configs... \U1F5D1 \n"
  rm -rf "$FABLO_NETWORK_ROOT/fabric-config/config"
  rm -rf "$FABLO_NETWORK_ROOT/fabric-config/crypto-config"
  rm -rf "$FABLO_NETWORK_ROOT/fabric-config/chaincode-packages"

  printHeadline "Done! Network was purged" "U1F5D1"
}
