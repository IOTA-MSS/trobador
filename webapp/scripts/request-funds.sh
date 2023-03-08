#!/bin/bash

# Go to wallet directory
cd /app/wallet

ADDR="$1"

# Check first argument is a valid eth address
if [[ $ADDR =~ ^0x[a-fA-F0-9]{40}$ ]]
then
    # Sends funds
    wasp-cli request-funds
    wasp-cli chain deposit $ADDR base:100000000 --chain=tangletunes
else
    # Throw error
    echo "Wrong argument: invalid eth address" 1>&2
    exit 69
fi