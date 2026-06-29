<%/*
  Chaincode install and upgrade for V2 capabilities.

  Required bash variables:
   - version
  Required template parameters:
   - chaincode
   - global
*/-%>
printHeadline "Packaging chaincode '<%= chaincode.name %>'" "U1F60E"
<% if (chaincode.lang === "ccaas") { -%>
  <% chaincode.channel.orgs.forEach((org) => { -%>
    <% const packageInstance = chaincode.peerChaincodeInstances.find((ci) => ci.orgName === org.name); -%>
    chaincodePackageCCaaS <% -%>
      "<%= org.cli.address %>" <% -%>
      "<%= chaincode.name %>" <% -%>
      "$version" <% -%>
      "<%= chaincode.channel.name %>" <% -%>
      "<%= packageInstance.packageLabel %>" <% -%>
      "<%= org.peers.map((peer) => peer.address).join(',') %>" <% -%>
      "<%= org.domain %>" <% -%>
      "<%= global.tls %>"
  <% }) -%>
<% } else { -%>
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
    "<%= chaincode.channel.name %>"
<% } -%>
<% chaincode.channel.orgs.forEach((org) => { -%>
  printHeadline "Installing '<%= chaincode.name %>' for <%= org.name %>" "U1F60E"
  <% org.peers.forEach((peer, i) => { -%>
    <% const instance = chaincode.lang === "ccaas" ? chaincode.peerChaincodeInstances.find((ci) => ci.peerAddress === peer.address) : undefined; -%>
    chaincodeInstall <% -%>
      "<%= org.cli.address %>" <% -%>
      "<%= peer.fullAddress %>" <% -%>
      "<%= chaincode.name %>" <% -%>
      "$version" <% -%>
      "<%= chaincode.channel.name %>" <% -%>
      "<%= !global.tls ? '' : `crypto-orderer/tlsca.${chaincode.channel.ordererHead.domain}-cert.pem` %>" <% -%>
      "<%= instance ? instance.packageLabel : '' %>"
  <% }) -%>
  <% const packageInstance = chaincode.lang === "ccaas" ? chaincode.peerChaincodeInstances.find((ci) => ci.orgName === org.name) : undefined; -%>
  chaincodeApprove <% -%>
    "<%= org.cli.address %>" <% -%>
    "<%= org.headPeer.fullAddress %>" <% -%>
    "<%= chaincode.channel.name %>" <% -%>
    "<%= chaincode.name %>" <% -%>
    "$version" <% -%>
    "<%= chaincode.channel.ordererHead.fullAddress %>" <% -%>
    "<%- chaincode.endorsement || '' %>" <% -%>
    "<%= chaincode.initRequired %>" <% -%>
    "<%= !global.tls ? '' : `crypto-orderer/tlsca.${chaincode.channel.ordererHead.domain}-cert.pem` %>" <% -%>
    "<%= chaincode.privateDataConfigFile || '' %>" <% -%>
    "<%= packageInstance ? packageInstance.packageLabel : '' %>"
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
  "<%= chaincode.initRequired %>" <% -%>
  "<%= !global.tls ? '' : `crypto-orderer/tlsca.${chaincode.channel.ordererHead.domain}-cert.pem` %>" <% -%>
  "<%= chaincode.channel.orgs.map((o) => o.headPeer.fullAddress).join(',') %>" <% -%>
  "<%= !global.tls ? '' : chaincode.channel.orgs.map(o => `crypto-peer/${o.headPeer.address}/tls/ca.crt`).join(',') %>" <% -%>
  "<%= chaincode.privateDataConfigFile || '' %>"
<% if (chaincode.lang === "ccaas") { -%>
  printHeadline "Starting CCaaS containers for '<%= chaincode.name %>'" "U1F680"
  <% chaincode.channel.orgs.forEach((org) => { -%>
    <% org.peers.forEach((peer) => { -%>
      <% const instance = chaincode.peerChaincodeInstances.find((ci) => ci.peerAddress === peer.address); -%>
      startCCaaSContainer <% -%>
        "<%= peer.fullAddress %>" <% -%>
        "<%= chaincode.name %>" <% -%>
        "<%= instance.packageLabel %>" <% -%>
        "<%= org.cli.address %>" <% -%>
        "<%= !global.tls ? '' : `crypto-orderer/tlsca.${chaincode.channel.ordererHead.domain}-cert.pem` %>" <% -%>
        "<%= instance.containerName %>" <% -%>
        "<%= global.tls %>"
    <% }) -%>
  <% }) -%>
<% } -%>
