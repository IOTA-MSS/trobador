const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

describe("Song Management", function () {
    async function deployedContractFixture() {
        const Contract = await ethers.getContractFactory("TangleTunes")
        const contract = await Contract.deploy()
        await contract.deployed()
    
        const [deployer, validator, rightholder, author, addr1] = await ethers.getSigners()
        await contract.connect(validator).create_user("Validator", "")
        await contract.connect(rightholder).create_user("Rightholder", "")
        await contract.connect(author).create_user("Author", "")
        await contract.manage_validators(validator.address)

        const song = {
            author: author.address,
            name: "abcd",
            price: 123,
            length: 456,
            duration: 789,
            chunks: [`0x${"12".repeat(32)}`, `0x${"34".repeat(32)}`, `0x${"56".repeat(32)}`]
        }

        song.signature = await rightholder.signMessage(ethers.utils.defaultAbiCoder.encode([
            "address",
            "string",
            "uint256",
            "uint256",
            "uint256",
            "bytes32[]"
        ], Object.values(song)))

        return { contract, song, deployer, validator, rightholder, author, addr1 }
    }

    it("Validator should be able to upload a song", async function () {
        const { contract, song, deployer, validator, rightholder, addr1 } = await loadFixture(deployedContractFixture)
        //compute song identification value
        const song_id = ethers.utils.solidityKeccak256(["string", "address"], [song.name, song.author])
        expect(await contract.gen_song_id(song.name, song.author)).to.equal(song_id)
        //only validator can upload song
        await expect(contract.connect(deployer).upload_song(...Object.values(song)))
            .to.be.revertedWith('User do not exist');
        await expect(contract.connect(rightholder).upload_song(...Object.values(song)))
            .to.be.revertedWith('User do not exist');
        await expect(contract.connect(addr1).upload_song(...Object.values(song)))
            .to.be.revertedWith('User do not exist');

        await contract.connect(validator).upload_song(...Object.values(song))

        expect(await contract.song_list_length()).to.equal(1)
        expect(await contract.song_list(0)).to.equal(song_id)
        console.log(`song_id: ${song_id}`)
        console.log(`songs: ${await contract.songs(song_id)}`)
        console.log(`get_songs: ${await contract.get_songs(0,1)}`)
    });
});