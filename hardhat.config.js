require("@nomicfoundation/hardhat-toolbox");
require('hardhat-abi-exporter');

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  defaultNetwork: "local",
  abiExporter: {
    runOnCompile: true,
    clear: true
  },
  networks: {
    local: {
      url: "http://127.0.0.1:9090/chains/tst1pqadsqpg4r3thmym3q68nmugy98h4u03re3yr6kcaxmwcedvw3wdv9rlqvz/evm",
      accounts: [
        "730beca56c3a79efce0b7022f9a060a4ace324e4cc01bd3b2cba408e6737c97b", // deployer
        "225f350b8c9f561b3ddd87c57eb735eb7cc983138deed3dfd210bf57fa8a9969", // account_1
        "32edf8c0260e0e74a60728c50b6c8e4697b8a599a7165505864d20aa0285d82c", // account_2
        "ce8bfd33ecba4dbcb42ac2808c9e858e11117726dda18be9c1863a11351aa054", // account_3
        "ecfd9045bca31d1df4124aca8457bdfd4340039b149b445166b9760313249f20", // account_4
        "6462f32a2b2a8541f3aa0008012ce17cb056fd38a4818ba16f1800dc48d4f832", // account_5
      ],
      timeout: 60000
    }
  }
};
