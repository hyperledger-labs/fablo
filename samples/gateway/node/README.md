# Purpose
To provide an example connection of Fablo with Node.js.

# Pre-requisites
Docker

Node >22

Git

# Instructions
1. (If Fablo is not already installed) Clone the Fablo repo with `https://github.com/hyperledger-labs/fablo.git` and then `cd fablo`.
2. Start Docker.
3. Run `fablo up samples/fablo-config-hlf3-1orgs-1chaincode.json`.
4. Once Fablo is running, run `cd samples/gateway/node`.
5. Now install the Node server's dependencies with `npm i`.
6. Now let's copy the environment example to a usable file `cp .env.example .env`.
7. Start the node server with `node --env-file=.env server.js`.

You should see a response like this:
```
Put result: {"success":"OK"}
Get result: {"success":"2025-04-29T16:13:42.097Z"}`
```

