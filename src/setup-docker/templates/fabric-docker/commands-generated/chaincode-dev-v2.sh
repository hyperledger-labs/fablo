<%/*
  Run chaincode in dev mode for V2 capabilities.

  Required template parameters:
   - chaincode
*/-%>
<% chaincode.channel.orgs.forEach((org) => { -%>
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
  printHeadline "Launching devmode chaincode runtime for '<%= chaincode.name %>'" "U1F680"
  startDevModeChaincodeProcess <% -%>
    "<%= chaincode.name %>" <% -%>
    "<%= chaincode.version %>" <% -%>
    "<%= chaincode.lang %>" <% -%>
    "$CHAINCODES_BASE_DIR/<%= chaincode.directory %>" <% -%>
    "<%= chaincode.instantiatingOrg.mspName %>" <% -%>
    "peerOrganizations/<%= org.domain %>/peers/<%= chaincode.instantiatingOrg.headPeer.address %>/tls/ca.crt" <% -%>
    "peerOrganizations/<%= chaincode.channel.ordererHead.domain %>/tlsca/tlsca.<%= chaincode.channel.ordererHead.domain %>-cert.pem" <% -%>
    "<%= global.tls %>" <% -%>
    "<%= chaincode.instantiatingOrg.headPeer.address %>" <% -%>
    "<%= org.domain %>"

<% } -%>
<% }) -%>
