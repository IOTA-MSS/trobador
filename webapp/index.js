const express = require('express');
const { ethers } = require('ethers');

const app = express();
const provider = ethers.getDefaultProvider('http://127.0.0.1:9090/chains/tst1pqadsqpg4r3thmym3q68nmugy98h4u03re3yr6kcaxmwcedvw3wdv9rlqvz/evm'); // replace with your desired Ethereum network

app.get('/', async (req, res) => {
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