const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

describe("Account Management", function () {
    async function deployedContractFixture() {
        const Contract = await ethers.getContractFactory("TangleTunes")
        const contract = await Contract.deploy()
        await contract.deployed()

        const [deployer, addr1] = await ethers.getSigners()
        return { contract, deployer, addr1 }
    }

    it("User Should be able to create account", async function () {
        const { contract, addr1 } = await loadFixture(deployedContractFixture)
        await contract.connect(addr1).create_user("Tester", "Desc");
        //cannot create account with account
        await expect(contract.connect(addr1).create_user("abc", "xyz"))
            .to.be.revertedWith('User already exists');
        
        const { exists, username, description } = await contract.users(addr1.address)
        expect(exists).to.equal(true);
        expect(username).to.equal("Tester");
        expect(description).to.equal("Desc");
    });

    it("User Should be able to edit description", async function () {
        const { contract, addr1 } = await loadFixture(deployedContractFixture)
        //cannot edit description without account
        await expect(contract.connect(addr1).edit_description("xyz"))
            .to.be.revertedWith('User do not exist');

        await contract.connect(addr1).create_user("Tester", "Desc");
        await contract.connect(addr1).edit_description("abc")
        
        const { description } = await contract.users(addr1.address)
        expect(description).to.equal("abc");
    });

    it("User Should be able to edit server info", async function () {
        const { contract, addr1 } = await loadFixture(deployedContractFixture)
        //cannot edit server info without account
        await expect(contract.connect(addr1).edit_server_info("127.0.0.1:3000"))
            .to.be.revertedWith('User do not exist');

        await contract.connect(addr1).create_user("Tester", "Desc");
        await contract.connect(addr1).edit_server_info("127.0.0.1:3000")
        
        const { server } = await contract.users(addr1.address)
        expect(server).to.equal("127.0.0.1:3000");
    });

    it("User Should be able to remove account", async function () {
        const { contract, addr1 } = await loadFixture(deployedContractFixture)
        //cannot delete account without account
        await expect(contract.connect(addr1).delete_user())
            .to.be.revertedWith('User do not exist');

        await contract.connect(addr1).create_user("Tester", "Desc");
        await contract.connect(addr1).delete_user()
        
        const { exists } = await contract.users(addr1.address)
        expect(exists).to.equal(false);
    });
});