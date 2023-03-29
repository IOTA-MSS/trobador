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
            nonce: await contract.get_author_of_length(author.address)
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

        //upload song
        await contract.connect(validator).upload_song(...Object.values(song))

        //check song obj
        const expected_values = [true,author.address,rightholder.address,validator.address,song.name,song.price,song.length,song.duration]
        const values = await contract.songs(song_id)
        expected_values.map(function(v, i) {
            expect(v).to.equal(values[i])
        });
        expect(await contract.chunks_length(song_id)).to.equal(song.chunks.length)
        Object.values(await contract.check_chunks(song_id, 0, song.chunks.length)).map(function(v, i) {
            expect(v).to.equal(song.chunks[i])
        })
        //song_list updated correctly
        expect(await contract.song_list_length()).to.equal(1)
        expect(await contract.song_list(0)).to.equal(song_id)
        await song_listing_works(await contract.get_songs(0, 1), song_id, song)
        //author_of updated correctly
        expect(await contract.get_author_of_length(author.address)).to.equal(1)
        expect(await contract.get_author_of_song_id(author.address, 0)).to.equal(song_id)
        await song_listing_works(await contract.get_author_of_songs(author.address, 0, 1), song_id, song)
        //holds_rights_to updated correctly
        expect(await contract.get_holds_rights_to_length(rightholder.address)).to.equal(1)
        expect(await contract.get_holds_rights_to_song_id(rightholder.address, 0)).to.equal(song_id)
        await song_listing_works(await contract.get_holds_rights_to_songs(rightholder.address, 0, 1), song_id, song)
        //validates updated correctly
        expect(await contract.get_validates_length(validator.address)).to.equal(1)
        expect(await contract.get_validates_song_id(validator.address, 0)).to.equal(song_id)
        await song_listing_works(await contract.get_validates_songs(validator.address, 0, 1), song_id, song)
    });

    it("Author & Rightholder should be able to change the price of a song", async function () {
        const { contract, song, deployer, validator, rightholder, author, addr1 } = await loadFixture(deployedContractFixture)
        //upload song
        const song_id = ethers.utils.solidityKeccak256(["string", "address"], [song.name, song.author])
        await contract.connect(validator).upload_song(...Object.values(song))
        //only Author & Rightholder can change price
        await expect(contract.connect(deployer).edit_price(song_id, 1111))
            .to.be.revertedWith('Only Author & Rightholder are allowed');
        await expect(contract.connect(validator).edit_price(song_id, 1111))
            .to.be.revertedWith('Only Author & Rightholder are allowed');
        await expect(contract.connect(addr1).edit_price(song_id, 1111))
            .to.be.revertedWith('Only Author & Rightholder are allowed');

        //Author can change price
        await contract.connect(author).edit_price(song_id, 2222)
        expect((await contract.songs(song_id)).price).to.equal(2222)

        //Rightholder can change price
        await contract.connect(rightholder).edit_price(song_id, 3333)
        expect((await contract.songs(song_id)).price).to.equal(3333)
    })

    it("Validator & Author & Rightholder should be able to delete their songs", async function () {
        const { contract, song, deployer, validator, rightholder, author, addr1 } = await loadFixture(deployedContractFixture)
        //upload song
        const song_id = ethers.utils.solidityKeccak256(["string", "address"], [song.name, song.author])
        await contract.connect(validator).upload_song(...Object.values(song))
        //only Validator & Author & Rightholder can delete song
        await expect(contract.connect(deployer).delete_song(song_id))
            .to.be.revertedWith('Only Validator & Author & Rightholder are allowed');
        await expect(contract.connect(addr1).delete_song(song_id))
            .to.be.revertedWith('Only Validator & Author & Rightholder are allowed');

        //Author can delete song
        expect((await contract.songs(song_id)).exists).to.equal(true)
        await contract.connect(author).delete_song(song_id)
        expect((await contract.songs(song_id)).exists).to.equal(false)

        //Rightholder can delete song
        await contract.connect(validator).upload_song(...Object.values(song))
        expect((await contract.songs(song_id)).exists).to.equal(true)
        await contract.connect(rightholder).delete_song(song_id)
        expect((await contract.songs(song_id)).exists).to.equal(false)

        //Validator can delete song
        await contract.connect(validator).upload_song(...Object.values(song))
        expect((await contract.songs(song_id)).exists).to.equal(true)
        await contract.connect(validator).delete_song(song_id)
        expect((await contract.songs(song_id)).exists).to.equal(false)
    })

    it("Song deletion when validator is dismissed", async function () {
        const { contract, song, validator } = await loadFixture(deployedContractFixture)
        //upload song
        const song_id = ethers.utils.solidityKeccak256(["string", "address"], [song.name, song.author])
        await contract.connect(validator).upload_song(...Object.values(song))

        //dismiss validator
        expect((await contract.songs(song_id)).exists).to.equal(true)
        await contract.manage_validators(validator.address)
        expect((await contract.songs(song_id)).exists).to.equal(false)
    })

    it("Song deletion when Author deletes their account", async function () {
        const { contract, song, validator, author } = await loadFixture(deployedContractFixture)
        //upload song
        const song_id = ethers.utils.solidityKeccak256(["string", "address"], [song.name, song.author])
        await contract.connect(validator).upload_song(...Object.values(song))

        //delete Author account
        expect((await contract.songs(song_id)).exists).to.equal(true)
        await contract.connect(author).delete_user()
        expect((await contract.songs(song_id)).exists).to.equal(false)
    })

    it("Song deletion when Rightholder deletes their account", async function () {
        const { contract, song, validator, rightholder } = await loadFixture(deployedContractFixture)
        //upload song
        const song_id = ethers.utils.solidityKeccak256(["string", "address"], [song.name, song.author])
        await contract.connect(validator).upload_song(...Object.values(song))

        //delete Author account
        expect((await contract.songs(song_id)).exists).to.equal(true)
        await contract.connect(rightholder).delete_user()
        expect((await contract.songs(song_id)).exists).to.equal(false)
    })

    it("Song deletion when Validator deletes their account", async function () {
        const { contract, song, validator } = await loadFixture(deployedContractFixture)
        //upload song
        const song_id = ethers.utils.solidityKeccak256(["string", "address"], [song.name, song.author])
        await contract.connect(validator).upload_song(...Object.values(song))

        //delete Author account
        expect((await contract.songs(song_id)).exists).to.equal(true)
        await contract.connect(validator).delete_user()
        expect((await contract.songs(song_id)).exists).to.equal(false)
    })
});