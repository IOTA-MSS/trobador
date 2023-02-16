# TangleTunes Smart Contract

## Test and Deploy
This project uses Hardhat to test the smart contract functionalities.

- Run automated tests:
```shell
npx hardhat test
```
- Deploy smart contract
```
npx hardhat run scripts/deploy.js
```

## Set up testing environment
This project uses the latest IOTA nodes to form a private tangle where the platform can be tested.

#### Build Wasp-CLI
- clone wasp repository
```
git clone https://github.com/iotaledger/wasp.git
git checkout v0.5.0-alpha.6
```
- compile program
```
make build
```
- add program to path
```
sudo cp wasp-cli /usr/bin/
```

#### Build node containers
- download the docker-compose file (Copied from the [IOTA repository](https://github.com/iotaledger/wasp/tree/v0.5.0-alpha.6)):
```
https://raw.githubusercontent.com/TangleTunes/smart_contract/main/docker-compose.yml
```
- start containers
```
docker compose up
```

#### Set up chain
- create IOTA wallet
```
wasp-cli init
wasp-cli set l1.apiaddress http://localhost:14265
wasp-cli set l1.faucetaddress http://localhost:8091
wasp-cli wasp add 0 http://localhost:9090
```
- obtain funds and deploy chain
```
wasp-cli request-funds
wasp-cli chain deploy --quorum=1 --chain=testchain --description="Test Chain"
```
