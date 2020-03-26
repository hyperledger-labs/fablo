function createChannelAndJoin() {
  local CHANNEL_NAME=$1

  local CORE_PEER_LOCALMSPID=$2
  local CORE_PEER_ADDRESS=$3
  local CORE_PEER_MSPCONFIGPATH=$(realpath $4)

  local ORDERER_URL=$5

  local DIR_NAME=step-createChannelAndJoin

  echo "Creating channel with name: ${CHANNEL_NAME}"
  echo "   Orderer: $ORDERER_URL"
  echo "   CORE_PEER_LOCALMSPID: $CORE_PEER_LOCALMSPID"
  echo "   CORE_PEER_ADDRESS: $CORE_PEER_ADDRESS"
  echo "   CORE_PEER_MSPCONFIGPATH: $CORE_PEER_MSPCONFIGPATH"

  mkdir $DIR_NAME && cd $DIR_NAME

  cp /var/hyperledger/cli/config/"$CHANNEL_NAME".tx .

  peer channel create -o ${ORDERER_URL} -c ${CHANNEL_NAME} -f ./"$CHANNEL_NAME".tx
  peer channel join -b ${CHANNEL_NAME}.block

  rm -rf $DIR_NAME
}

function fetchChannelAndJoin() {
  local CHANNEL_NAME=$1

  local CORE_PEER_LOCALMSPID=$2
  local CORE_PEER_ADDRESS=$3
  local CORE_PEER_MSPCONFIGPATH=$(realpath $4)

  local ORDERER_URL=$5

  local DIR_NAME=step-fetchChannelAndJoin

  echo "Fetching channel with name: ${CHANNEL_NAME}"
  echo "   Orderer: $ORDERER_URL"
  echo "   CORE_PEER_LOCALMSPID: $CORE_PEER_LOCALMSPID"
  echo "   CORE_PEER_ADDRESS: $CORE_PEER_ADDRESS"
  echo "   CORE_PEER_MSPCONFIGPATH: $CORE_PEER_MSPCONFIGPATH"

  mkdir $DIR_NAME && cd $DIR_NAME

  peer channel fetch newest -c ${CHANNEL_NAME} --orderer ${ORDERER_URL}
  peer channel join -b ${CHANNEL_NAME}_newest.block

  rm -rf $DIR_NAME
}

function createChannelAndJoinTls() {
  local CHANNEL_NAME=$1

  local CORE_PEER_LOCALMSPID=$2
  local CORE_PEER_ADDRESS=$3
  local CORE_PEER_MSPCONFIGPATH=$(realpath $4)

  local TLS_CA_CERT_PATH=$(realpath $5)
  local ORDERER_URL=$6

  local DIR_NAME=step-createChannelAndJoinTls

  echo "Creating channel with name (via TLS): ${CHANNEL_NAME}"
  echo "   Orderer: $ORDERER_URL"
  echo "   CORE_PEER_LOCALMSPID: $CORE_PEER_LOCALMSPID"
  echo "   CORE_PEER_ADDRESS: $CORE_PEER_ADDRESS"
  echo "   CORE_PEER_MSPCONFIGPATH: $CORE_PEER_MSPCONFIGPATH"
  echo "   TLS_CA_CERT_PATH is : $TLS_CA_CERT_PATH"

  mkdir $DIR_NAME && cd $DIR_NAME

  cp /var/hyperledger/cli/config/"$CHANNEL_NAME".tx .

  peer channel create -o ${ORDERER_URL} -c ${CHANNEL_NAME} -f ./"$CHANNEL_NAME".tx --tls --cafile $TLS_CA_CERT_PATH
  peer channel join -b ${CHANNEL_NAME}.block --tls --cafile $TLS_CA_CERT_PATH

  rm -rf $DIR_NAME
}

function fetchChannelAndJoinTls() {
  local CHANNEL_NAME=$1

  local CORE_PEER_LOCALMSPID=$2
  local CORE_PEER_ADDRESS=$3
  local CORE_PEER_MSPCONFIGPATH=$(realpath $4)

  local TLS_CA_CERT_PATH=$(realpath $5)
  local ORDERER_URL=$6

  local DIR_NAME=step-fetchChannelAndJoin

  echo "Fetching channel with name: ${CHANNEL_NAME}"
  echo "   Orderer: $ORDERER_URL"
  echo "   CORE_PEER_LOCALMSPID: $CORE_PEER_LOCALMSPID"
  echo "   CORE_PEER_ADDRESS: $CORE_PEER_ADDRESS"
  echo "   CORE_PEER_MSPCONFIGPATH: $CORE_PEER_MSPCONFIGPATH"

  mkdir $DIR_NAME && cd $DIR_NAME

  peer channel fetch newest -c ${CHANNEL_NAME} --orderer ${ORDERER_URL} --tls --cafile $TLS_CA_CERT_PATH
  peer channel join -b ${CHANNEL_NAME}_newest.block --tls --cafile $TLS_CA_CERT_PATH

  rm -rf $DIR_NAME
}
