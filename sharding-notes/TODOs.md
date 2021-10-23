1. Zmiany w Fablo config
    - wywalić całkiem root org
    - wywalić ordererOrgs i zrobić orga z podziałem
    - dodać groupName w ordrerConfig

2. Zmiany extendConfig  
   - wszystkie orgi bez sekcji peerów to ordererOrgi

3. Walidacja:
   - orderery w tej samej grupie musze miec ten sam consensus type
   - nie mozna joinowac do kanału organizacji bez peerów
   - 

wszystkie orgi posiadajace orderera maja takie cos:
```
PeerOrgs:
- Name: Org1
  Domain: org1.example.com
  EnableNodeOUs: true
  Specs:
   - Hostname: orderer0
   - Hostname: orderer1
   - Hostname: peer0
   - Hostname: peer1
     Users:
     Count: 0
- Name: Org2
  Domain: org2.example.com
  EnableNodeOUs: true
  Specs:
   - Hostname: orderer0
   - Hostname: orderer1
   - Hostname: peer0
   - Hostname: peer1
     Users:
     Count: 0
```     


## === Linki ===

[decentralized ordering service with peer org owned orderers](https://kctheservant.medium.com/decentralized-ordering-service-with-peer-org-owned-orderers-d0939ea026f6)

[how-to-implement-decentralized-orderer-or-say-peer-org-owned-orderer-in-hyperled](https://stackoverflow.com/questions/66811077/how-to-implement-decentralized-orderer-or-say-peer-org-owned-orderer-in-hyperled)

[Using Orderer nodes without genesis block in HLF >= 2.3](https://hyperledger-fabric.readthedocs.io/en/release-2.3/create_channel/create_channel_participation.html)
