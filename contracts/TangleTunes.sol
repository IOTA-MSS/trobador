// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./documentation/TangleTunes.sol";


contract TangleTunes is TangleTunesI {
    address public owner = msg.sender;
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

    function song_list_length() external view returns (uint256) {
        return song_list.length;
    }

    function get_songs_from_list(bytes32[] memory _list, uint256 _index, uint256 _amount) internal view returns (Song_listing[] memory) {
        //Check all indexes are valid
        require(_index + _amount <= _list.length, "Indexes out of bounds");

        Song_listing[] memory lst = new Song_listing[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            bytes32 song_id = _list[_index + i];

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

    function get_songs(uint256 _index, uint256 _amount) external view returns (Song_listing[] memory) {
        return get_songs_from_list(song_list, _index, _amount);
    }

    function get_author_of_songs(address _user, uint _index, uint _amount) external view returns (Song_listing[] memory) {
        return get_songs_from_list(users[_user].author_of, _index, _amount);
    }

    function get_holds_rights_to_songs(address _user, uint _index, uint _amount) external view returns (Song_listing[] memory) {
        return get_songs_from_list(users[_user].holds_rights_to, _index, _amount);
    }

    function get_validates_songs(address _user, uint _index, uint _amount) external view returns (Song_listing[] memory) {
        return get_songs_from_list(users[_user].validates, _index, _amount);
    }

    function manage_validators(address _validator) external onlyOwner {
        User storage validator = users[_validator];
        require(validator.exists, "Validator is not a valid user");

        //remove all validated songs
        if (validator.is_validator) {
            delete_all_songs_in_list(validator.validates);
        }

        //switch validator status
        validator.is_validator = !validator.is_validator;
    }

    function create_user(string memory _name, string memory _desc) external {
        require(!users[msg.sender].exists, "User already exists");
        
        User memory user_object;
        user_object.exists = true;
        user_object.username = _name;
        user_object.description = _desc;

        users[msg.sender] = user_object;
    }

    function get_author_of_length(address _user) external view returns (uint256) {
        return users[_user].author_of.length;
    }

    function get_author_of_song_id(address _user, uint256 _index) external view returns (bytes32) {
        return users[_user].author_of[_index];
    }

    function get_holds_rights_to_length(address _user) external view returns (uint256) {
        return users[_user].holds_rights_to.length;
    }

    function get_holds_rights_to_song_id(address _user, uint256 _index) external view returns (bytes32) {
        return users[_user].holds_rights_to[_index];
    }

    function get_validates_length(address _user) external view returns (uint256) {
        return users[_user].validates.length;
    }

    function get_validates_song_id(address _user, uint256 _index) external view returns (bytes32) {
        return users[_user].validates[_index];
    }

    function delete_all_songs_in_list(bytes32[] storage _list) internal {
        for (uint256 i = 0; i < _list.length; i++) {
            delete songs[_list[i]];
        }
    }

    function delete_user() external userExists {
        User storage user = users[msg.sender];
        require(user.balance == 0, "Can't delete account with balance");

        //remove all songs with involvement
        delete_all_songs_in_list(user.author_of);
        delete_all_songs_in_list(user.holds_rights_to);
        delete_all_songs_in_list(user.validates);

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

    function withdraw_to_chain(uint256 _amount) external userExists {
        User storage user = users[msg.sender];
        require(user.balance >= _amount, "User do not have the demanded balance");
        user.balance -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function withdraw_to_tangle(uint64 _amount, L1Address memory _target) external userExists {
        User storage user = users[msg.sender];
        require(user.balance >= _amount, "User do not have the demanded balance");

        ISCSendMetadata memory metadata;
        ISCSendOptions memory options;
        ISCAssets memory assets;
        assets.baseTokens = _amount;
        ISC.sandbox.send(_target, assets, false, metadata, options);

        payable(msg.sender).transfer(_amount);
    }

    function upload_song(
        address _author, 
        string memory _name, 
        uint256 _price, 
        uint256 _length, 
        uint256 _duration, 
        bytes32[] memory _chunks,
        uint256 _nonce,
        bytes memory _signature
    ) external {
        require(users[msg.sender].is_validator, "Only validators are allowed");

        //Get rightholder from signed parameters
        bytes32 _msgHash = keccak256(abi.encodePacked(_author, _name, _price, _length, _duration, _chunks, _nonce));
        address _rightholder = recoverSigner(_msgHash, _signature);
        require(users[_rightholder].exists, "Rightholder is not a valid user");
        require(users[_author].exists, "Author is not a valid user");

        //Compute song id
        bytes32 _song = gen_song_id(_name, _author);
        require(!songs[_song].exists, "Song is already uploaded");

        //Create and upload song's object
        Song memory song_obj;
        song_obj.exists = true;
        song_obj.author = _author;
        song_obj.rightholder = _rightholder;
        song_obj.validator = msg.sender;
        song_obj.name = _name;
        song_obj.price = _price;
        song_obj.length = _length;
        song_obj.duration = _duration;
        song_obj.chunks = _chunks;
        songs[_song] = song_obj;

        //Add song id to lists
        song_list.push(_song);
        users[_author].author_of.push(_song);
        users[_rightholder].holds_rights_to.push(_song);
        users[msg.sender].validates.push(_song);
    }

    //https://solidity-by-example.org/signature/
    function recoverSigner(bytes32 _messageHash, bytes memory _signature) internal pure returns (address) {
        bytes32 _ethMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function gen_song_id(string memory _name, address _author) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_name, _author));
    }

    function edit_price(bytes32 _song, uint256 _price) external songExists(_song) {
        Song storage song_obj = songs[_song];
        require(msg.sender == song_obj.author || msg.sender == song_obj.rightholder, "Only Author & Rightholder are allowed");
        song_obj.price = _price;
    }

    function delete_song(bytes32 _song) external songExists(_song) {
        Song storage song_obj = songs[_song];
        require(msg.sender == song_obj.author || msg.sender == song_obj.rightholder || msg.sender == song_obj.validator, "Only Validator & Author & Rightholder are allowed");
        delete songs[_song];
    }

    function gen_distribution_id(bytes32 _song, address _distributor) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_song, _distributor));
    }

    function distribute(bytes32 _song, uint256 _fee) external songExists(_song) userExists {
        //Compute distribution id
        bytes32 _dist_id = gen_distribution_id(_song, msg.sender);

        //Store distribution object and list distributor of song
        address[] storage song_dists = songs[_song].distributors;
        distributions[_dist_id] = Distribution(true, song_dists.length, _fee);
        song_dists.push(msg.sender);
    }

    function edit_fee(bytes32 _song, uint256 _fee) external songExists(_song) {
        //Compute distribution id
        bytes32 _dist_id = gen_distribution_id(_song, msg.sender);
        require(distributions[_dist_id].exists, "Song is not being distributed");

        //Change distribution fee
        distributions[_dist_id].fee = _fee;
    }

    function undistribute(bytes32 _song) external songExists(_song) {
        //Compute distribution id
        bytes32 _dist_id = gen_distribution_id(_song, msg.sender);
        require(distributions[_dist_id].exists, "Song is not being distributed");

        //Unlist from song distribution and delete object
        //TODO: remove from distributors list without leaving empty space
        delete songs[_song].distributors[distributions[_dist_id].index];
        delete distributions[_dist_id];
    }
    
    //TODO: provide based on distribution fee and/or staking value (+ some randomness)
    //TODO: add _amount argument
    function get_rand_distributor(bytes32 _song) external songExists(_song) view returns (address, string memory) {
        //TODO: Get random distributor index
        //uint256 _rand = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % song_dists.length;

        address[] storage song_dists = songs[_song].distributors;
        address _distributor = address(0);
        for (uint256 i = 0; i < song_dists.length && _distributor == address(0); i++) {
            _distributor = song_dists[i];
        }
        
        // return address and server information
        return (_distributor, users[_distributor].server);
    }

    function chunks_length(bytes32 _song) external songExists(_song) view returns (uint) {
        return songs[_song].chunks.length;
    }

    function get_chunks(bytes32 _song, uint256 _index, uint256 _amount, address _distributor) external userExists songExists(_song) {
        //Check distributor is valid,  and index is valid
        bytes32 _dist_id = gen_distribution_id(_song, _distributor);
        Distribution storage dist_obj = distributions[_dist_id];
        require(dist_obj.exists, "Distributor is not currently active");

        //Check indexes are valid
        Song storage song_obj = songs[_song];
        require(_index + _amount <= song_obj.chunks.length, "Indexes out of bounds");

        //Check user has enough funds
        uint256 total_price = (song_obj.price + dist_obj.fee) * _amount;
        require(users[msg.sender].balance >= total_price, "User do not have enough funds");

        // Distribute balance
        users[msg.sender].balance -= total_price;
        users[song_obj.author].balance += song_obj.price * _amount;
        users[_distributor].balance += dist_obj.fee * _amount;
    }

    function check_chunks(bytes32 _song, uint256 _index, uint256 _amount) external songExists(_song) view returns (bytes32[] memory) {
        //Check indexes are valid
        bytes32[] storage song_chunks = songs[_song].chunks;
        require(_index + _amount <= song_chunks.length, "Indexes out of bounds");

        //return requested chunks
        bytes32[] memory _chunks = new bytes32[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            _chunks[i] = song_chunks[_index + i];
        }
        return _chunks;
    }
}