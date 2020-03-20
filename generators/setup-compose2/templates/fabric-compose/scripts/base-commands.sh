function networkUp() {
  printf "============ \U1F913 Generating configs \U1F913 ================= \n"
  certsGenerate "fabric-config" "./fabric-config/crypto-config"
  genesisBlockCreate "fabric-config" "./fabric-config/config"

  printf "============ \U1F680 Starting network \U1F680 ================== \n"
  cd fabric-compose
  docker-compose up -d
  cd ..

  printf "============ \U1F984 Done! Enjoy your fresh network \U1F984 ==== \n"
}

function networkDown() {
  printf "============ \U1F916 Stopping network \U1F916 ================== \n"
  cd fabric-compose
  docker-compose down
  cd ..

  printf "\nRemoving generates configs ... \U1F5D1 \n"
  rm -rf fabric-config/config
  rm -rf fabric-config/crypto-config

  printf "============ \U1F5D1 Done! Network was purged \U1F5D1 ============= \n"
}

function networkRerun() {
  networkDown
  networkUp
}
