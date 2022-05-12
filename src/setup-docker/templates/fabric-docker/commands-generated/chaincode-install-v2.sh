<%/*
  Chaincode install and upgrade for V2 capabilities.

  Required bash variables:
   - version
  Required template parameters:
   - chaincode
   - global
*/-%>
printHeadline "Packaging chaincode '<%= chaincode.name %>'" "U1F60E"
chaincodeBuild <% -%>
  "<%= chaincode.name %>" <% -%>
  "<%= chaincode.lang %>" <% -%>
  "$CHAINCODES_BASE_DIR/<%= chaincode.directory %>" <% -%>
  "<%= global.fabricRecommendedNodeVersion %>"
chaincodePackage <% -%>
  "<%= chaincode.instantiatingOrg.cli.address %>" <% -%>
  "<%= chaincode.instantiatingOrg.headPeer.fullAddress %>" <% -%>
  "<%= chaincode.name %>" <% -%>
  "$version" <% -%>
  "<%= chaincode.lang %>" <% -%>
<% chaincode.channel.orgs.forEach((org) => { -%>
  printHeadline "Installing '<%= chaincode.name %>' for <%= org.name %>" "U1F60E"
  <% org.peers.forEach((peer) => { -%>
    chaincodeInstall <% -%>
      "<%= org.cli.address %>" <% -%>
      "<%= peer.fullAddress %>" <% -%>
      "<%= chaincode.name %>" <% -%>
      "$version" <% -%>
      "<%= !global.tls ? '' : `crypto-orderer/tlsca.${chaincode.channel.ordererHead.domain}-cert.pem` %>"
  <% }) -%>
  chaincodeApprove <% -%>
    "<%= org.cli.address %>" <% -%>
    "<%= org.headPeer.fullAddress %>" <% -%>
    "<%= chaincode.channel.name %>" <% -%>
    "<%= chaincode.name %>" <% -%>
    "$version" <% -%>
    "<%= chaincode.channel.ordererHead.fullAddress %>" <% -%>
    "<%- chaincode.endorsement || '' %>" <% -%>
    "<%= `${chaincode.initRequired}` %>" <% -%>
    "<%= !global.tls ? '' : `crypto-orderer/tlsca.${chaincode.channel.ordererHead.domain}-cert.pem` %>" <% -%>
    "<%= chaincode.privateDataConfigFile || '' %>"
<% }) -%>
printItalics "Committing chaincode '<%= chaincode.name %>' on channel '<%= chaincode.channel.name %>' as '<%= chaincode.instantiatingOrg.name %>'" "U1F618"
chaincodeCommit <% -%>
  "<%= chaincode.instantiatingOrg.cli.address %>" <% -%>
  "<%= chaincode.instantiatingOrg.headPeer.fullAddress %>" <% -%>
  "<%= chaincode.channel.name %>" <% -%>
  "<%= chaincode.name %>" <% -%>
  "$version" <% -%>
  "<%= chaincode.channel.ordererHead.fullAddress %>" <% -%>
  "<%- chaincode.endorsement || '' %>" <% -%>
  "<%= `${chaincode.initRequired}` %>" <% -%>
  "<%= !global.tls ? '' : `crypto-orderer/tlsca.${chaincode.channel.ordererHead.domain}-cert.pem` %>" <% -%>
  "<%= chaincode.channel.orgs.map((o) => o.headPeer.fullAddress).join(',') %>" <% -%>
  "<%= !global.tls ? '' : chaincode.channel.orgs.map(o => `crypto-peer/${o.headPeer.address}/tls/ca.crt`).join(',') %>" <% -%>
  "<%= chaincode.privateDataConfigFile || '' %>"
