require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  defaultNetwork: "local",
  networks: {
    local: {
      url: "http://127.0.0.1:9090/chains/tst1pqadsqpg4r3thmym3q68nmugy98h4u03re3yr6kcaxmwcedvw3wdv9rlqvz/evm",
      accounts: ["730beca56c3a79efce0b7022f9a060a4ace324e4cc01bd3b2cba408e6737c97b"],
      timeout: 60000
    }
  }
};
