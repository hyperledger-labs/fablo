FROM node:18-alpine3.14

RUN apk add --no-cache sudo shfmt
RUN npm install --global --silent yo

# copy fablo files
COPY generators /fablo/generators
COPY package.json /fablo/package.json
COPY package-lock.json /fablo/package-lock.json

# copy files for init network
COPY samples/fablo-config-hlf2-1org-1chaincode.json /fablo/generators/init/templates/fablo-config.json
COPY samples/chaincodes/chaincode-kv-node /fablo/generators/init/templates/chaincodes/chaincode-kv-node

WORKDIR /fablo
RUN npm install --silent --only=prod
RUN npm link

# Add a yeoman user because Yeoman freaks out and runs setuid(501).
# This was because less technical people would run Yeoman as root and cause problems.
# Setting uid to 501 here since it's already a random number being thrown around.
# @see https://github.com/yeoman/yeoman.github.io/issues/282
# @see https://github.com/cthulhu666/docker-yeoman/blob/master/Dockerfile
# @see https://github.com/phase2/docker-yeoman/blob/master/Dockerfile
RUN adduser -D -u 501 yeoman && \
  echo "yeoman ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Yeoman needs the use of a home directory for caching and certain config storage.
ENV HOME /network/workspace

COPY docker-entrypoint.sh /fablo/docker-entrypoint.sh
COPY docs /fablo/docs
COPY README.md /fablo/README.md
COPY samples /fablo/samples/

ARG VERSION_DETAILS
RUN echo "{ \"buildInfo\": \"$VERSION_DETAILS\" }" > /fablo/version.json
RUN cat /fablo/version.json

CMD /fablo/docker-entrypoint.sh
