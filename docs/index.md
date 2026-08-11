---
layout: home
title: Home
---

<section class="home-section" id="why-fablo" aria-labelledby="why-fablo-heading">
  <p class="section-kicker">Why Fablo?</p>
  <h2 class="section-heading" id="why-fablo-heading">A better starting point</h2>
  <p class="section-subheading">The network is complex. Your setup shouldn't be.</p>
  <div class="section-copy">
    <p>Setting up a Hyperledger Fabric network by hand means writing dozens of crypto, configtx, and Docker Compose files. Fablo replaces all of that with a single declarative config: describe the organizations, channels, and chaincodes you want, and Fablo generates the network and the scripts to operate it on Docker — with TLS, RAFT/BFT ordering, CouchDB or LevelDB, private data, chaincode-as-a-service, Fablo REST, and optional Blockchain Explorer for Fabric v2.</p>
    <p>Fablo is built for local development and CI: spin up a full network in seconds, run chaincode and integration tests against it, then tear it down and repeat the process reliably on any machine with Docker.</p>
  </div>
</section>

<section class="home-section" id="how-it-works" aria-labelledby="how-it-works-heading">
  <p class="section-kicker">How it works</p>
  <h2 class="section-heading" id="how-it-works-heading">From config to a running network</h2>
  <div class="steps">
    <article class="step-card">
      <span class="step-number">01</span>
      <h3>Describe your network</h3>
      <p>Keep organizations, channels, and chaincodes in one readable config file.</p>
      <pre aria-label="Example network configuration"><code>network: fabric
version: 3.1.0</code></pre>
    </article>
    <article class="step-card">
      <span class="step-number">02</span>
      <h3>Generate everything</h3>
      <p>Fablo creates the artifacts and scripts your local network needs.</p>
      <pre aria-label="Commands to generate a network"><code>fablo init node
fablo generate</code></pre>
    </article>
    <article class="step-card">
      <span class="step-number">03</span>
      <h3>Build and iterate</h3>
      <p>Run locally on Docker, test fast, then ship the same setup to CI.</p>
      <pre aria-label="Command to start a network"><code>fablo up</code></pre>
    </article>
  </div>
</section>
