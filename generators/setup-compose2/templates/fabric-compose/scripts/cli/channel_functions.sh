function createChannelTls() {
  echo "Creating channel with name: ${CHANNEL_NAME}"
  echo "TLS_CA_CERT_PATH is : ${TLS_CA_CERT_PATH}"

  mkdir -p /var/steps/createchannel && cd /var/steps/createchannel

  cp /var/hyperledger/cli/channel-artifacts/channel.tx .

  peer channel create -o ${ORDERER_URL} -c ${CHANNEL_NAME} -f ./channel.tx --tls --cafile $TLS_CA_CERT_PATH
  peer channel join -b ${CHANNEL_NAME}.block --tls --cafile $TLS_CA_CERT_PATH

  rm -rf /var/steps/createchannel
}

function createChannel() {
  local CHANNEL_NAME=$1
  local ORDERER=$2
  local ORDERER_URL=$2

  local CORE_PEER_LOCALMSPID=$3
  local CORE_PEER_ADDRESS=$4
  local CORE_PEER_MSPCONFIGPATH=$(realpath $5)

  local DIR_NAME=stepcreatechannel

  echo "Creating channel with name: ${CHANNEL_NAME}"
  echo "   Orderer: $ORDERER"
  echo "   CORE_PEER_LOCALMSPID: $CORE_PEER_LOCALMSPID"
  echo "   CORE_PEER_ADDRESS: $CORE_PEER_ADDRESS"
  echo "   CORE_PEER_MSPCONFIGPATH: $CORE_PEER_MSPCONFIGPATH"

  mkdir $DIR_NAME && cd $DIR_NAME

  cp /var/hyperledger/cli/config/"$CHANNEL_NAME".tx .

  peer channel create -o ${ORDERER} -c ${CHANNEL_NAME} -f ./"$CHANNEL_NAME".tx
#  peer channel join -b ${FCHANNEL_NAME}.block

#  rm -rf $DIR_NAME
}

#touch scripts/channel_functions.sh && \
createChannel "channel" "orderer.example.com:7050" "Org1MSP" "peer0.org1.com:7051" "crypto/peerOrganizations/org1.com/users/Admin@org1.com/msp"

# TODO 1 - wyciągnąć zmienne
# TODO 2 - jak podawać channel.tx
# TODO 3 - czy zawsze ten sam orderer? NIE!
# TODO 4 - kiedy skrypt będzie generyczny ?

# TODO 5 - fajnie to by było mieć channel.tx jako "bloba"

# TODO 6 - try/catch w bashu
