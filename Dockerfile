FROM node:14-alpine

# Yeoman needs the use of a home directory for caching and certain config storage.
ENV HOME /home/yeoman

RUN apk add --no-cache sudo

# Add a yeoman user because Yeoman freaks out and runs setuid(501).
# This was because less technical people would run Yeoman as root and cause problems.
# Setting uid to 501 here since it's already a random number being thrown around.
# @see https://github.com/yeoman/yeoman.github.io/issues/282
# @see https://github.com/cthulhu666/docker-yeoman/blob/master/Dockerfile
# @see https://github.com/phase2/docker-yeoman/blob/master/Dockerfile
RUN adduser -D -u 501 yeoman && \
  echo "yeoman ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY generators /fabrikka/generators
COPY docs /fabrikka/docs
COPY package.json /fabrikka/
COPY package-lock.json /fabrikka/

COPY samples /fabrikka/samples

WORKDIR /fabrikka

RUN npm install --global --silent yo
RUN npm install
RUN npm link

USER yeoman

RUN cd samples
RUN yo fabrikka:setup-compose fabrikkaConfig-1org-1channel-1chaincode.json

CMD ["bash"]

#https://www.octobot.io/blog/2016-02-25-running-yeoman-in-a-development-instance-in-docker/
