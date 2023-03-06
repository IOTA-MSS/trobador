#!/bin/bash

# go to wallet directory
cd /app/wallet

# install wasp's command line wallet
if ! test -f wasp-cli
then
    wget 'https://github.com/iotaledger/wasp/releases/download/v0.5.0-alpha.6/wasp-cli_0.5.0-alpha.6_Linux_x86_64.tar.gz'
    gunzip 'wasp-cli_0.5.0-alpha.6_Linux_x86_64.tar.gz'
    tar -xvf 'wasp-cli_0.5.0-alpha.6_Linux_x86_64.tar'
    mv 'wasp-cli_0.5.0-alpha.6_Linux_x86_64/wasp-cli' .
    rm -r 'wasp-cli_0.5.0-alpha.6_Linux_x86_64' 'wasp-cli_0.5.0-alpha.6_Linux_x86_64.tar'
fi

# TODO: initialize wallet

# TODO: request funds

# TODO: deploy chain

# TODO: 