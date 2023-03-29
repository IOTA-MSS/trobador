const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

describe("Validator Management", function () {
    async function deployedContractFixture() {
        const Contract = await ethers.getContractFactory("TangleTunes")
        const contract = await Contract.deploy()
        await contract.deployed()
    
        const [deployer, validator, addr1] = await ethers.getSigners()
        await contract.connect(validator).create_user("Validator", "")

        return { contract, deployer, validator, addr1 }
    }

    it("Deployer should be able to assign a validator", async function () {
        const { contract, validator, addr1 } = await loadFixture(deployedContractFixture)
        //normal users cannot assign validators
        await expect(contract.connect(validator).manage_validators(validator.address))
            .to.be.revertedWith('Only owner is allowed');
        await expect(contract.connect(addr1).manage_validators(validator.address))
            .to.be.revertedWith('Only owner is allowed');

        //cannot assign validator a user without account
        await expect(contract.manage_validators(addr1.address))
            .to.be.revertedWith('Validator is not a valid user');

        await contract.manage_validators(validator.address)
        
        expect((await contract.users(validator.address)).is_validator).to.equal(true);
        expect((await contract.users(addr1.address)).is_validator).to.equal(false);
    });

    it("Deployer should be able to dismiss a validor", async function () {
        const { contract, validator, addr1 } = await loadFixture(deployedContractFixture)
        
        await contract.manage_validators(validator.address)
        await contract.manage_validators(validator.address)
        
        expect((await contract.users(validator.address)).is_validator).to.equal(false);
    });
});