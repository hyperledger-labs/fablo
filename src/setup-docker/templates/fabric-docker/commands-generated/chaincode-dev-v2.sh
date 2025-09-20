<%/*
  Run chaincode in dev mode for V2 capabilities.

  Required bash variables:
   - version
  Required template parameters:
   - chaincode
*/-%>
<% chaincode.channel.orgs.forEach((org) => { -%>
  chaincodePackage <% -%>
    "<%= chaincode.instantiatingOrg.cli.address %>" <% -%>
    "<%= chaincode.instantiatingOrg.headPeer.fullAddress %>" <% -%>
    "<%= chaincode.name %>" <% -%>
    "$version" <% -%>
    "<%= chaincode.lang %>" <% -%>
  <% org.peers.forEach((peer, i) => { -%>
    printHeadline "Installing '<%= chaincode.name %>' for <%= org.name %>" "U1F60E"
    chaincodeInstall <% -%>
      "<%= org.cli.address %>" <% -%>
      "<%= peer.fullAddress %>" <% -%>
      "<%= chaincode.name %>" <% -%>
      "$version" <% -%>
      "<%= !global.tls ? '' : `crypto-orderer/tlsca.${chaincode.channel.ordererHead.domain}-cert.pem` %>"
  <% }) -%>
  printHeadline "Approving '<%= chaincode.name %>' for <%= org.name %> (dev mode)" "U1F60E"
  chaincodeApprove <% -%>
    "<%= org.cli.address %>" <% -%>
    "<%= org.headPeer.fullAddress %>" <% -%>
    "<%= chaincode.channel.name %>" <% -%>
    "<%= chaincode.name %>" <% -%>
    "<%= chaincode.version %>" <% -%>
    "<%= chaincode.channel.ordererHead.fullAddress %>" <% -%>
    "<%- chaincode.endorsement || '' %>" <% -%>
    "false" <% -%>
    "<%= !global.tls ? '' : `crypto-orderer/tlsca.${chaincode.channel.ordererHead.domain}-cert.pem` %>" <% -%>
    "<%= chaincode.privateDataConfigFile || '' %>" <% -%>
    "" <% -%>
    ""
  printItalics "Committing chaincode '<%= chaincode.name %>' on channel '<%= chaincode.channel.name %>' as '<%= chaincode.instantiatingOrg.name %>' (dev mode)" "U1F618"
  chaincodeCommit <% -%>
    "<%= chaincode.instantiatingOrg.cli.address %>" <% -%>
    "<%= chaincode.instantiatingOrg.headPeer.fullAddress %>" <% -%>
    "<%= chaincode.channel.name %>" <% -%>
    "<%= chaincode.name %>" <% -%>
    "<%= chaincode.version %>" <% -%>
    "<%= chaincode.channel.ordererHead.fullAddress %>" <% -%>
    "<%- chaincode.endorsement || '' %>" <% -%>
    "false" <% -%>
    "<%= !global.tls ? '' : `crypto-orderer/tlsca.${chaincode.channel.ordererHead.domain}-cert.pem` %>" <% -%>
    "<%= chaincode.channel.orgs.map((o) => o.headPeer.fullAddress).join(',') %>" <% -%>
    "<%= !global.tls ? '' : chaincode.channel.orgs.map(o => `crypto-peer/${o.headPeer.address}/tls/ca.crt`).join(',') %>" <% -%>
    "<%= chaincode.privateDataConfigFile || '' %>"
<% if (global.tls) { -%>
  printHeadline "Generating TLS certs to be used by '<%= chaincode.name %>'" "U1F680"
  certsGenerateCCaaS <% -%>
    "$FABLO_NETWORK_ROOT/fabric-config/crypto-config/" <% -%>
    "devmode-<%= chaincode.name %>" <% -%>
    "<%= org.domain %>" <% -%>
    "<%= chaincode.name %>" <% -%>
    "<%= chaincode.instantiatingOrg.headPeer.address %>"
<% } -%>
<% }) -%>
