const { ethers } = require("hardhat");

async function main() {
  const Contract = await ethers.getContractFactory("TangleTunes");
  const contract = await Contract.deploy();

  await contract.deployed();

  console.log(`TangleTunes deployed to ${contract.address} with deployer: ${contract.signer.address}`);
}

// Properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
