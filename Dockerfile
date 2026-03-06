FROM node:20-alpine

RUN apk add --no-cache shfmt

# copy fablo files
COPY generators /fablo/generators
COPY package.json /fablo/package.json
COPY package-lock.json /fablo/package-lock.json

# copy files for init network
COPY samples/chaincodes/chaincode-kv-node /fablo/generators/init/templates/chaincodes/chaincode-kv-node
COPY samples/gateway/node /fablo/generators/init/templates/gateway/node

WORKDIR /fablo
RUN npm install --silent --only=prod
RUN npm link

COPY docker-entrypoint.sh /fablo/docker-entrypoint.sh
COPY bin /fablo/bin
COPY bin/run.mjs /fablo/bin/run.mjs
COPY docs /fablo/docs
COPY README.md /fablo/README.md
COPY samples /fablo/samples/

ARG VERSION_DETAILS
RUN echo "{ \"buildInfo\": \"$VERSION_DETAILS\" }" > /fablo/version.json
RUN cat /fablo/version.json

CMD ["/fablo/docker-entrypoint.sh"]
