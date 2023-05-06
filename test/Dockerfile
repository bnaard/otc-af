# Use Ubuntu minimal as the base image
FROM ubuntu:22.04


RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    sudo \
    lsb-release

RUN wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install necessary packages
RUN apt-get update && apt-get install -y \
    golang \
    terraform 

RUN mkdir -p /workdir/test
RUN mkdir -p /workdir/src

COPY src/ /workdir/src
COPY test/*.go /workdir/test

WORKDIR /workdir