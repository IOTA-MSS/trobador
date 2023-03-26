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
            chunks: [`0x${"12".repeat(32)}`, `0x${"34".repeat(32)}`, `0x${"56".repeat(32)}`],
            nonce: await contract.get_user_nonce(author.address)
        }

        song.sig = await rightholder.signMessage(ethers.utils.arrayify(ethers.utils.solidityKeccak256([
            "address",
            "string",
            "uint256",
            "uint256",
            "uint256",
            "bytes32[]",
            "uint256"
        ], Object.values(song))))

        return { contract, song, deployer, validator, rightholder, author, addr1 }
    }

    async function song_listing_works(output, song_id, song) {
        const [ _songs_id, _songs_name, _songs_author, _songs_price, _songs_length, _songs_duration ] = output[0]

        expect(_songs_id).to.equal(song_id)
        expect(_songs_name).to.equal(song.name)
        expect(_songs_author).to.equal("Author")
        expect(_songs_price).to.equal(song.price)
        expect(_songs_length).to.equal(song.length)
        expect(_songs_duration).to.equal(song.duration)
    }

    it("Validator should be able to upload a song", async function () {
        const { contract, song, deployer, validator, rightholder, author, addr1 } = await loadFixture(deployedContractFixture)
        //compute song identification value
        const song_id = ethers.utils.solidityKeccak256(["string", "address"], [song.name, song.author])
        expect(await contract.gen_song_id(song.name, song.author)).to.equal(song_id)
        //only validator can upload song
        await expect(contract.connect(deployer).upload_song(...Object.values(song)))
            .to.be.revertedWith('Only validators are allowed');
        await expect(contract.connect(rightholder).upload_song(...Object.values(song)))
            .to.be.revertedWith('Only validators are allowed');
        await expect(contract.connect(author).upload_song(...Object.values(song)))
            .to.be.revertedWith('Only validators are allowed');
        await expect(contract.connect(addr1).upload_song(...Object.values(song)))
            .to.be.revertedWith('Only validators are allowed');

        await contract.connect(validator).upload_song(...Object.values(song))

        const [ _exists, _author, _rightholder, _validator, _name, _price, _length, _duration ] = await contract.songs(song_id);
        expect(_exists).to.equal(true)
        expect(_author).to.equal(author.address)
        expect(_rightholder).to.equal(rightholder.address)
        expect(_validator).to.equal(validator.address)
        expect(_name).to.equal(song.name)
        expect(_price).to.equal(song.price)
        expect(_length).to.equal(song.length)
        expect(_duration).to.equal(song.duration)
        expect(await contract.chunks_length(song_id)).to.equal(song.chunks.length)
        //song_list updated correctly
        expect(await contract.song_list_length()).to.equal(1)
        expect(await contract.song_list(0)).to.equal(song_id)
        //user's song_list updated correctly
        expect(await contract.get_user_nonce(author.address)).to.equal(1)
        expect(await contract.get_user_song_list(author.address, 0)).to.equal(song_id)
        //get_songs working
        await song_listing_works(await contract.get_songs(0, 1), song_id, song)
        //get_user_songs
        await song_listing_works(await contract.get_user_songs(author.address, 0, 1), song_id, song)
    });
});