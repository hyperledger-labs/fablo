<%/*
  Chaincode install for V1 capabilities.

  Required template parameters:
   - chaincode
   - global
*/-%>
chaincodeBuild <% -%>
  "<%= chaincode.name %>" <% -%>
  "<%= chaincode.lang %>" <% -%>
  "$CHAINCODES_BASE_DIR/<%= chaincode.directory %>" <% -%>
  "<%= global.fabricRecommendedNodeVersion %>"
<% chaincode.channel.orgs.forEach((org) => { -%>
  <% org.peers.forEach((peer) => { -%>
    printHeadline "Installing '<%= chaincode.name %>' on <%= chaincode.channel.name %>/<%= org.name %>/<%= peer.name %>" "U1F60E"
    chaincodeInstall <% -%>
      "<%= org.cli.address %>" <% -%>
      "<%= peer.fullAddress %>" <% -%>
      "<%= chaincode.channel.name %>" <% -%>
      "<%= chaincode.name %>" <% -%>
      "<%= chaincode.version %>" <% -%>
      "<%= chaincode.lang %>" <% -%>
      "<%= chaincode.channel.ordererHead.fullAddress %>" <% -%>
      "<%= !global.tls ? '' : `crypto-orderer/tlsca.${chaincode.channel.ordererHead.domain}-cert.pem` %>"
  <% }) -%>
<% }) -%>
printItalics "Instantiating chaincode '<%= chaincode.name %>' on channel '<%= chaincode.channel.name %>' as '<%= chaincode.instantiatingOrg.name %>'" "U1F618"
chaincodeInstantiate <% -%>
  "<%= chaincode.instantiatingOrg.cli.address %>" <% -%>
  "<%= chaincode.instantiatingOrg.headPeer.fullAddress %>" <% -%>
  "<%= chaincode.channel.name %>" <% -%>
  "<%= chaincode.name %>" <% -%>
  "<%= chaincode.version %>" <% -%>
  "<%= chaincode.lang %>" <% -%>
  "<%= chaincode.channel.ordererHead.fullAddress %>" <% -%>
  '<%- chaincode.init %>' <% -%>
  "<%- chaincode.endorsement %>" <% -%>
  "<%= !global.tls ? '' : `crypto-orderer/tlsca.${chaincode.channel.ordererHead.domain}-cert.pem` %>" <% -%>
  "<%= chaincode.privateDataConfigFile || '' %>"
