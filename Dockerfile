FROM node:14-alpine

RUN apk add --no-cache sudo docker-cli docker-compose
RUN npm install --global --silent yo

COPY docs /fabrikka/docs
COPY generators /fabrikka/generators
COPY docker-entrypoint.sh /fabrikka/docker-entrypoint.sh
COPY package.json /fabrikka/package.json
COPY package-lock.json /fabrikka/package-lock.json
COPY README.md /fabrikka/README.md

WORKDIR /fabrikka
RUN npm install --silent
RUN npm link

# Add a yeoman user because Yeoman freaks out and runs setuid(501).
# This was because less technical people would run Yeoman as root and cause problems.
# Setting uid to 501 here since it's already a random number being thrown around.
# @see https://github.com/yeoman/yeoman.github.io/issues/282
# @see https://github.com/cthulhu666/docker-yeoman/blob/master/Dockerfile
# @see https://github.com/phase2/docker-yeoman/blob/master/Dockerfile
# RUN adduser -D -u 501 yeoman && \
#   echo "yeoman ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Yeoman needs the use of a home directory for caching and certain config storage.
ENV HOME /home/yeoman

WORKDIR /fabrikka
ENTRYPOINT /fabrikka/docker-entrypoint.sh
