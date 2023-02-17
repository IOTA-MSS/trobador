const { expect } = require("chai");

describe("TangleTunes", function () {
  async function deployedContract() {
    const Contract = await ethers.getContractFactory("TangleTunes");
    const [_owner, _addr1, _addr2] = await ethers.getSigners();
    const _contract = await Contract.deploy();
    await _contract.deployed();
    return { _contract, _owner, _addr1, _addr2 };
  }

  describe("Account Management", function () {
    let { contract, owner, addr1, addr2 } = [null, null, null, null]

    before(async function () {
      let { _contract, _owner, _addr1, _addr2 }  = await deployedContract();
      contract = _contract
      owner = _owner
      addr1 = _addr1
      addr2 = _addr2
      console.log(`New contract deployed at ${contract.address}`)
    })

    it("Should be able to create account", async function () {
      await contract.create_user("Tester", "Desc");
      
      let { exists } = await contract.users(owner.address)
      expect(exists).to.equal(true);
    });
  });
});
