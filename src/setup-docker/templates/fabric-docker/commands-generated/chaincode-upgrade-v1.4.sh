<%/*
  Upgrade chaincode for V1 capabilities.

  Required bash variables:
   - version
  Required template parameters:
   - chaincode
   - networkSettings
*/-%>
chaincodeBuild <% -%>
  "<%= chaincode.name %>" <% -%>
  "<%= chaincode.lang %>" <% -%>
  "$CHAINCODES_BASE_DIR/<%= chaincode.directory %>"
<% chaincode.channel.orgs.forEach(function (org) { -%>
  <% org.peers.forEach(function (peer) { %>
    printHeadline "Installing '<%= chaincode.name %>' on <%= chaincode.channel.name %>/<%= org.name %>/<%= peer.name %>" "U1F60E"
    chaincodeInstall <% -%>
      "<%= org.cli.address %>" <% -%>
      "<%= peer.fullAddress %>" <% -%>
      "<%= chaincode.channel.name %>" <% -%>
      "<%= chaincode.name %>" <% -%>
      "$version" <% -%>
      "<%= chaincode.lang %>" <% -%>
      "<%= chaincode.channel.ordererHead.fullAddress %>" <% -%>
      "<%= !networkSettings.tls ? '' : `crypto-orderer/tlsca.${chaincode.channel.ordererHead.domain}-cert.pem` %>"
  <% }) -%>
<% }) -%>
printItalics "Upgrading as '<%= chaincode.instantiatingOrg.name %>'. '<%= chaincode.name %>' on channel '<%= chaincode.channel.name %>'" "U1F618"
chaincodeUpgrade <% -%>
  "<%= chaincode.instantiatingOrg.cli.address %>" <% -%>
  "<%=  chaincode.instantiatingOrg.headPeer.fullAddress %>" <% -%>
  "<%= chaincode.channel.name %>" "<%= chaincode.name %>" <% -%>
  "$version" <% -%>
  "<%= chaincode.lang %>" <% -%>
  "<%= chaincode.channel.ordererHead.fullAddress %>" <% -%>
  '<%- chaincode.init %>' <% -%>
  "<%- chaincode.endorsement %>" <% -%>
  "<%= !networkSettings.tls ? '' : `crypto-orderer/tlsca.${chaincode.channel.ordererHead.domain}-cert.pem` %>" <% -%>
  "<%= chaincode.privateDataConfigFile || '' %>"
