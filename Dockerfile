FROM node:14.16-alpine3.12

RUN apk add --no-cache sudo shfmt
RUN npm install --global --silent yo

# copy fabrica files
COPY generators /fabrica/generators
COPY package.json /fabrica/package.json
COPY package-lock.json /fabrica/package-lock.json

# copy files for init network
COPY samples/fabrica-config-hlf2-1org-1chaincode.json /fabrica/generators/init/templates/fabrica-config.json
COPY samples/chaincodes/chaincode-kv-node /fabrica/generators/init/templates/chaincodes/chaincode-kv-node

WORKDIR /fabrica
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

COPY docker-entrypoint.sh /fabrica/docker-entrypoint.sh
COPY docs /fabrica/docs
COPY README.md /fabrica/README.md
COPY samples /fabrica/samples/

ARG VERSION_DETAILS
RUN echo "{ \"buildInfo\": \"$VERSION_DETAILS\" }" > /fabrica/version.json
RUN cat /fabrica/version.json

CMD /fabrica/docker-entrypoint.sh
