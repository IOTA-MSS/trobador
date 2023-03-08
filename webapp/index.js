const { ethers } = require('ethers');
const { execSync } = require('child_process');
const express = require('express');
const http = require('http');
const fs = require('fs');

function waitForWasp() {
  return new Promise((resolve, reject) => {
    http.get('http://wasp:7000/chains', async (res) => {
      (res.statusCode === 200) ? resolve() : await waitForWasp()
    }).on('error', (err) => {
      reject(err.message)
    }).end()
  })
}

(async () => {
  console.log('Waiting for server to start...')
  await waitForWasp()
})()

//Deploy chain and smart contract
execSync('/bin/bash /app/scripts/create-wallet.sh', 
  (error, stdout, _) => {
    console.log(stdout);
    if (error !== null) {
      console.log(`exec error: ${error}`);
    }
  }
);

const app = express();

let chainID = JSON.parse(fs.readFileSync('/app/wallet/wasp-cli.json')).chains.tangletunes
const provider = ethers.getDefaultProvider(`http://wasp:9090/chains/${chainID}/evm`);

app.get('/info', async (req, res) => {
  res.json({
    "json-rpc": `http://localhost:9090/chains/${chainID}/evm`,
    "chainID": 1074,
    "smart-contract": "TBD"
  });
});

app.get('/faucet/:addr', async (req, res) => {
  let success = true
  execSync(`/bin/bash /app/scripts/request-funds.sh ${req.params.addr}`, 
    (error, stdout, _) => {
      if (error !== null) {
        console.log(`exec error: ${error}`);
        success = false
      }
    }
  );
  res.json({"succes": success});
});

app.get('/history', async (req, res) => {
  const transactions = await provider.getBlock('latest').then(block => block.transactions);
  const txData = await Promise.all(transactions.map(async txHash => {
    const tx = await provider.getTransaction(txHash);
    return {
      hash: tx.hash,
      from: tx.from,
      to: tx.to,
      //value: ethers.utils.formatEther(tx.value),
      //gasPrice: ethers.utils.formatEther(tx.gasPrice),
      //gasLimit: tx.gasLimit,
      nonce: tx.nonce,
      blockNumber: tx.blockNumber
    }
  }));
  res.json(txData);
});

app.listen(3000, () => {
  console.log('Server started on port 3000');
});