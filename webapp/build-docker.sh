#!/bin/bash
docker build --tag=validator_app .
docker run -p 80:3000 --rm --name=validator_app -v wallet:/app/wallet