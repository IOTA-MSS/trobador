// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../documentation/TangleTunes.sol";

contract TangleTunes is TangleTunesI {
    address owner = msg.sender;

    mapping(address => User) public users;
    mapping(bytes32 => Song) public songs;
    mapping(bytes32 => Distribution) public distributions;
    bytes32[] public song_list;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    modifier userExists() {
        require(users[msg.sender].exists, "User do not exist");
        _;
    }

    modifier songExists(bytes32 song) {
        require(songs[song].exists, "Song do not exist");
        _;
    }

    modifier onlyValidator() {
        require(users[msg.sender].is_validator, "Only validators are allowed");
        _;
    }

    struct User {
        bool exists;
        string username;
        string description;
        string server; // TODO: separate into ip, port, public key
        uint256 balance;
        bool is_validator;
        // TODO: song list (after MVP Optional)
    }

    struct Song {
        bool exists;
        address author;
        string name;
        uint256 price;
        uint256 length;
        uint256 duration;
        bytes32[] chunks;
        address[] distributors; //TODO: sorted data structure
    }

    struct Distribution {
        bool exists;
        uint256 index;
        uint256 fee;
        //TODO: Staking value (after MVP)
    }

    function song_list_length() external view returns (uint256) {
        return song_list.length;
    }

    function get_songs(uint256 _index, uint256 _amount) external view returns (Song_listing[] memory) {
        //Check all indexes are valid
        require(_index + _amount < song_list.length, "Indexes out of bounds");

        Song_listing[] memory lst = new Song_listing[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            bytes32 song_id = song_list[_index + i];

            //Only add information if song is still available (Could have been removed)
            if (song_id != bytes32(0)) {
                Song storage song_obj = songs[song_id];
                lst[i] = Song_listing(
                    song_id,
                    song_obj.name,
                    users[song_obj.author].username,
                    song_obj.price,
                    song_obj.length,
                    song_obj.duration
                );

            }
        }
        
        return lst;
    }

    function manage_validators(address _validator) external onlyOwner {
        require(users[_validator].exists, "Validator is not a valid user");
        users[_validator].is_validator = !users[_validator].is_validator;
    }

    function create_user(string memory _name, string memory _desc) external {
        require(!users[msg.sender].exists, "User already exists");
        users[msg.sender] = User(true, _name, _desc, "", 0, false);
    }

    function delete_user() external userExists {
        //TODO: remove songs linked to this user
        delete users[msg.sender];
    }

    function edit_description(string memory _desc) external userExists {
        users[msg.sender].description = _desc;
    }

    //TODO: separate into ip, port, public key
    function edit_server_info(string memory _server) external userExists {
        users[msg.sender].server = _server;
    }

    function deposit() external userExists payable {
        users[msg.sender].balance += msg.value;
    }

    
    function withdraw(uint _amount, L1Address memory _target) external {
        //TODO: implement
    }

    function withdraw(uint256 amount) external userExists {
        uint256 balance = users[msg.sender].balance;
        require(balance >= amount, "User do not have the demanded balance");
        users[msg.sender].balance -= amount;
        payable(msg.sender).transfer(amount);
    }

    function upload_song(address _author, string memory _name, uint _price, uint _length, uint _duration, bytes32[] memory _chunks) external onlyValidator {
        require(users[_author].exists, "Author is not a valid user");
        
        //Compute song id
        bytes32 _song = gen_song_id(_name, _author);
        require(!songs[_song].exists, "Song is already uploaded");

        //Create and upload song's object
        Song memory song_obj;
        song_obj.exists = true;
        song_obj.author = _author;
        song_obj.name = _name;
        song_obj.price = _price;
        song_obj.length = _length;
        song_obj.duration = _duration;
        song_obj.chunks = _chunks;
        songs[_song] = song_obj;

        //Add song id to list
        song_list.push(_song);
    }

    function gen_song_id(string memory _name, address _author) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_name, _author));
    }

    function edit_price(bytes32 _song, uint256 _price) external songExists(_song) {
        Song storage song_obj = songs[_song];
        require(msg.sender == song_obj.author, "Only author is allowed");
        song_obj.price = _price;
    }

    function gen_distribution_id(bytes32 _song, address _distributor) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_song, _distributor));
    }

    function distribute(bytes32 _song, uint256 _fee) external songExists(_song) userExists {
        //Compute distribution id
        bytes32 _dist_id = gen_distribution_id(_song, msg.sender);
        address[] storage song_dists = songs[_song].distributors;

        //Store distribution object and list distributor of song
        distributions[_dist_id] = Distribution(true, song_dists.length, _fee);
        song_dists.push(msg.sender);
    }

    function undistribute(bytes32 _song) external {
        //Compute distribution id
        bytes32 _dist_id = gen_distribution_id(_song, msg.sender);

        //Unlist from song distribution and delete object
        //TODO: switch with last one in the last
        delete songs[_song].distributors[distributions[_dist_id].index];
        delete distributions[_dist_id];
    }
    
    //TODO: provide based on distribution fee and/or staking value (+ some randomness)
    function get_rand_distributor(bytes32 _song) external view returns (address){
        address[] storage song_dists = songs[_song].distributors;
        uint256 _rand = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % (song_dists.length-1);
        return song_dists[_rand+1];
    }

    function chunks_length(bytes32 _song) external view returns (uint) {
        return songs[_song].chunks.length;
    }

    function get_chunks(bytes32 _song, uint256 _index, uint256 _amount, address _distributor) external userExists {
        //Check distributor is valid,  and index is valid
        bytes32 _dist_id = gen_distribution_id(_song, _distributor);
        Distribution storage dist_obj = distributions[_dist_id];
        require(dist_obj.exists, "Distributor is not currently active");

        //Check indexes are valid
        Song storage song_obj = songs[_song];
        require(_index + _amount < song_obj.chunks.length, "Indexes out of bounds");

        //Check user has enough funds
        uint256 total_price = (song_obj.price + dist_obj.fee) * _amount;
        require(users[msg.sender].balance >= total_price, "User do not have enough funds");

        // Distribute balance
        users[msg.sender].balance -= total_price;
        users[song_obj.author].balance += song_obj.price;
        users[_distributor].balance += dist_obj.fee;
    }

    function check_chunk(bytes32 _song, uint256 _index, bytes32 _chunk) external view returns (bool) {
        return songs[_song].chunks[_index] == _chunk;
    }
}