---
layout: home
title: Home
---

<section class="home-section" id="why-fablo" aria-labelledby="why-fablo-heading">
  <p class="section-kicker">Why Fablo?</p>
  <h2 class="section-heading" id="why-fablo-heading">A better starting point</h2>
  <p class="section-subheading">One config file describes the whole network, and Fablo generates the rest.</p>
  <div class="section-copy">
    <p>Setting up a Hyperledger Fabric network by hand means writing dozens of crypto, configtx, and Docker Compose files. Fablo replaces all of that with a single config file in JSON or YAML, where you describe the organizations, channels, and chaincodes you want. Fablo then generates the network and the scripts that operate it on Docker, with TLS, private data collections, and CouchDB or LevelDB as the peer database. Chaincode can be written in Node.js, Go, or Java, and it can also run as a service (CCaaS) with hot reload of the source code. Ordering uses RAFT or BFT on Fabric v3, and RAFT or solo on Fabric v2. You can also enable <a href="https://github.com/fablo-io/fablo-rest">Fablo REST</a> for an organization, and Blockchain Explorer on Fabric v2.</p>
    <p>Fablo is built for local development and CI. You start a full network with one command, and then run chaincode and integration tests against it. When you are done, you tear the network down and repeat the process on any machine with Docker. A network from the sample config takes a few minutes to start. Fablo can also save a snapshot of a running network, so you can restore the same state later.</p>
  </div>
</section>

<section class="home-section" id="how-it-works" aria-labelledby="how-it-works-heading">
  <p class="section-kicker">How it works</p>
  <h2 class="section-heading" id="how-it-works-heading">From config to a running network</h2>
  <div class="steps">
    <article class="step-card">
      <span class="step-number">01</span>
      <h3>Describe your network</h3>
      <p>Fablo writes a starter config file with an orderer organization, a peer organization, a channel, and a sample Node.js chaincode.</p>
      <pre aria-label="Command to scaffold a network config"><code>fablo init node</code></pre>
    </article>
    <article class="step-card">
      <span class="step-number">02</span>
      <h3>Generate everything</h3>
      <p>Fablo writes the Fabric config, the Docker Compose files, and the network scripts into the <code>fablo-target</code> directory.</p>
      <pre aria-label="Command to generate a network"><code>fablo generate</code></pre>
    </article>
    <article class="step-card">
      <span class="step-number">03</span>
      <h3>Start the network</h3>
      <p>Fablo starts the network on Docker, then creates the channels and deploys the chaincodes.</p>
      <pre aria-label="Command to start a network"><code>fablo up</code></pre>
    </article>
  </div>
</section>
