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
    "" <% -%>
    "<%= chaincode.privateDataConfigFile || '' %>"
<% }) -%>
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
  "" <% -%>
  "<%= chaincode.channel.orgs.map((o) => o.headPeer.fullAddress).join(',') %>" <% -%>
  "" <% -%>
  "<%= chaincode.privateDataConfigFile || '' %>"
