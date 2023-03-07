#!/bin/bash

# Go to wallet directory
cd /app/wallet

# Install wasp's command line wallet
if ! command -v wasp-cli &> /dev/null
then
    echo "Installing wasp-cli"
    wget 'https://github.com/iotaledger/wasp/releases/download/v0.5.0-alpha.6/wasp-cli_0.5.0-alpha.6_Linux_x86_64.tar.gz'
    gunzip 'wasp-cli_0.5.0-alpha.6_Linux_x86_64.tar.gz'
    tar -xvf 'wasp-cli_0.5.0-alpha.6_Linux_x86_64.tar'
    mv 'wasp-cli_0.5.0-alpha.6_Linux_x86_64/wasp-cli' /usr/bin
    rm -r 'wasp-cli_0.5.0-alpha.6_Linux_x86_64' 'wasp-cli_0.5.0-alpha.6_Linux_x86_64.tar'
fi

# Initialize wallet
if ! wasp-cli address &> /dev/null
then
    echo "Initializing wallet"
    wasp-cli init
    wasp-cli set l1.apiaddress http://hornet-nest:14265
    wasp-cli set l1.faucetaddress http://hornet-nest:8091
    wasp-cli wasp add 0 http://wasp:9090
fi

# Deploy chain
if ! wasp-cli chain info --chain=tangletunes &> /dev/null
then
    echo "Deploying tangletunes chain"
    wasp-cli request-funds
    wasp-cli chain deploy --quorum=1 --chain=tangletunes --description="TangleTunes"
fi