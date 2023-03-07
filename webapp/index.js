const express = require('express');
const fs = require('fs');

const { ethers } = require('ethers');
const { execSync } = require('child_process');

const app = express();

//Deploy chain
execSync('sh /app/create-wallet.sh', 
  (error, stdout, stderr) => {
    console.log(stdout);
    console.log(stderr);
    if (error !== null) {
      console.log(`exec error: ${error}`);
    }
  }
);

let chainID = JSON.parse(fs.readFileSync('/app/wallet/wasp-cli.json')).chains.tangletunes
const provider = ethers.getDefaultProvider(`http://wasp:9090/chains/${chainID}/evm`);

app.get('/', async (req, res) => {
  res.json({
    "json-rpc": `http://localhost:9090/chains/${chainID}/evm`,
    "chainID": 1074,
    "smart-contract": "TBD"
  });
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