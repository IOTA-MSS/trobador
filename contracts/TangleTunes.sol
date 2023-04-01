// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./documentation/TangleTunes.sol";


contract TangleTunes is TangleTunesI {
    address public owner = msg.sender;
    mapping(address => User) public users;
    mapping(bytes32 => Song) public songs;
    mapping(bytes32 => Distribution) public distributions;
    bytes32[] public song_list;

    address private END = address(1);

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

    function _get_songs_from_list(bytes32[] memory _list, uint256 _index, uint256 _amount) internal view returns (Song_listing[] memory) {
        //Check all indexes are valid
        require(_index + _amount <= _list.length, "Indexes out of bounds");

        Song_listing[] memory lst = new Song_listing[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            bytes32 song_id = _list[_index + i];

            //Only add information if song is still available (Could have been removed)
            Song storage song_obj = songs[song_id];
            if (song_obj.exists) {
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
        return _get_songs_from_list(song_list, _index, _amount);
    }

    function get_author_of_songs(address _user, uint _index, uint _amount) external view returns (Song_listing[] memory) {
        return _get_songs_from_list(users[_user].author_of, _index, _amount);
    }

    function get_holds_rights_to_songs(address _user, uint _index, uint _amount) external view returns (Song_listing[] memory) {
        return _get_songs_from_list(users[_user].holds_rights_to, _index, _amount);
    }

    function get_validates_songs(address _user, uint _index, uint _amount) external view returns (Song_listing[] memory) {
        return _get_songs_from_list(users[_user].validates, _index, _amount);
    }

    function manage_validators(address _validator) external onlyOwner {
        User storage validator = users[_validator];
        require(validator.exists, "Validator is not a valid user");

        //remove all validated songs
        if (validator.is_validator) {
            _delete_all_songs_in_list(validator.validates);
        }

        //switch validator status
        validator.is_validator = !validator.is_validator;
    }

    function create_user(string memory _name, string memory _desc) external {
        require(!users[msg.sender].exists, "User already exists");
        
        //Create and store user's object
        User storage user_obj = users[msg.sender];
        user_obj.exists = true;
        user_obj.username = _name;
        user_obj.description = _desc;
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

    function _delete_all_songs_in_list(bytes32[] storage _list) internal {
        for (uint256 i = 0; i < _list.length; i++) {
            _undistribute_all(_list[i]);
            delete songs[_list[i]];
        }
    }

    function delete_user() external userExists {
        User storage user = users[msg.sender];
        require(user.balance == 0, "Can't delete account with balance");

        //remove all songs with involvement
        _delete_all_songs_in_list(user.author_of);
        _delete_all_songs_in_list(user.holds_rights_to);
        _delete_all_songs_in_list(user.validates);

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
        address _rightholder = _recoverSigner(_msgHash, _signature);
        require(users[_rightholder].exists, "Rightholder is not a valid user");
        require(users[_author].exists, "Author is not a valid user");
        require(_nonce == users[_author].author_of.length, "Nonce is incorrect");

        //Compute song id
        bytes32 _song = gen_song_id(_name, _author);
        require(!songs[_song].exists, "Song is already uploaded");

        //Create and store song's object
        Song storage song_obj = songs[_song];
        song_obj.exists = true;
        song_obj.author = _author;
        song_obj.rightholder = _rightholder;
        song_obj.validator = msg.sender;
        song_obj.name = _name;
        song_obj.price = _price;
        song_obj.length = _length;
        song_obj.duration = _duration;
        song_obj.chunks = _chunks;

        //Set up linked list head for distribution
        distributions[_song].next_distributor = END;

        //Add song id to lists
        song_list.push(_song);
        users[_author].author_of.push(_song);
        users[_rightholder].holds_rights_to.push(_song);
        users[msg.sender].validates.push(_song);
    }

    //https://solidity-by-example.org/signature/
    function _recoverSigner(bytes32 _messageHash, bytes memory _signature) internal pure returns (address) {
        bytes32 _ethMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);
        return ecrecover(_ethMessageHash, v, r, s);
    }

    function _splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
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
        require(msg.sender == song_obj.rightholder, "Only Rightholder is allowed");
        song_obj.price = _price;
    }

    function delete_song(bytes32 _song) external songExists(_song) {
        Song storage song_obj = songs[_song];
        require(msg.sender == song_obj.validator || msg.sender == song_obj.rightholder, "Only Validator & Rightholder are allowed");
        _undistribute_all(_song);
        delete songs[_song];
    }

    function gen_distribution_id(bytes32 _song, address _distributor) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_song, _distributor));
    }

    function _distribute(
        bytes32 _song, 
        uint256 _fee, 
        address _dist_index_addr, 
        address _insert_index_addr
    ) internal songExists(_song) userExists {
        //Compute distribution id
        bytes32 _dist_id = gen_distribution_id(_song, msg.sender);
        bytes32 _insert_index;
        if (_insert_index_addr == address(0)) {
            _insert_index = _song;
        } else {
            _insert_index = gen_distribution_id(_song, _insert_index_addr);
        } 

        //Remove existing distribution
        if (distributions[_dist_id].next_distributor != address(0)) {
            //Compute distributor index id
            bytes32 _dist_index;
            if (_dist_index_addr == address(0)) {
                _dist_index = _song;
            } else {
                _dist_index = gen_distribution_id(_song, _dist_index_addr);
            }
            require(distributions[_dist_index].next_distributor != address(0), "Distributor index is not distributing");
            require(_get_next_dist_id(_song, _dist_index) == _dist_id, "Incorrect distributor distributor");

            //Remove distributor from ordered list
            _remove_distribution(_song, _dist_id, _dist_index);
        }

        //Check index
        address _next_insert_addr = distributions[_insert_index].next_distributor;
        require(_next_insert_addr != address(0), "Insert Index is not distributing");
        require(_verify_index(_song, _insert_index, _fee), "Incorrect insert index");

        //Insert distributor in ordered list
        distributions[_dist_id] = Distribution(_fee, _next_insert_addr);
        distributions[_insert_index].next_distributor = msg.sender;

        //Increase stored amount of song distributors
        songs[_song].distributors += 1;
    }

    function distribute(
        bytes32[] memory _songs, 
        uint256[] memory _fees, 
        address[] memory _dist_index_addresses, 
        address[] memory _insert_index_addresses
    ) external {
        require(_songs.length == _fees.length && 
                _songs.length == _dist_index_addresses.length &&
                _songs.length == _insert_index_addresses.length, "Lists must be of same size");
        for (uint256 i = 0; i < _songs.length; i++) {
            _distribute(_songs[i], _fees[i], _dist_index_addresses[i], _insert_index_addresses[i]);
        }
    }

    function _undistribute(bytes32 _song, address _index_addr) internal songExists(_song) {
        //Compute distribution id
        bytes32 _dist_id = gen_distribution_id(_song, msg.sender);
        require(distributions[_dist_id].next_distributor != address(0), "Song is not being distributed");

        //Check previous distributor
        bytes32 _index;
        if (_index_addr == address(0)) {
            _index = _song;
        } else {
            _index = gen_distribution_id(_song, _index_addr);
        } 
        require(_get_next_dist_id(_song, _index) == _dist_id, "Incorrect distributor index");

        //Remove distributor from ordered list
        _remove_distribution(_song, _dist_id, _index);
    }

    function undistribute(bytes32[] memory _songs, address[] memory _index_addresses) external {
        require(_songs.length == _index_addresses.length, "Lists must be of same size");
        for (uint256 i = 0; i < _songs.length; i++) {
            _undistribute(_songs[i], _index_addresses[i]);
        }
    }

    function _find_insert_index(bytes32 _song, uint256 _fee) internal songExists(_song) view returns (address) {
        address _index_addr = address(0);
        bytes32 _index = _song;

        while(distributions[_index].next_distributor != END) {
            if (_verify_index(_song, _index, _fee)) {
                return _index_addr;
            }
            
            _index_addr = distributions[_index].next_distributor;
            _index = _get_next_dist_id(_song, _index);
        }

        return _index_addr;
    }

    function find_insert_indexes(bytes32[] memory _songs, uint256[] memory _fees) external view returns (address[] memory) {
        require(_songs.length == _fees.length, "Lists must be of same size");

        address[] memory insert_indexes = new address[](_songs.length);
        for (uint256 i = 0; i < _songs.length; i++) {
            insert_indexes[i] = _find_insert_index(_songs[i], _fees[i]);
        }

        return insert_indexes;
    }

    function _find_dist_index(bytes32 _song, address _dist_addr) internal songExists(_song) view returns (address) {
        //Compute distribution id
        bytes32 _dist_id = gen_distribution_id(_song, _dist_addr);
        if (distributions[_dist_id].next_distributor == address(0)) {
            return address(0);
        }

        address _index_addr = address(0);
        bytes32 _index = _song;
        while (distributions[_index].next_distributor != END) {
            bytes32 _next_dist_id = _get_next_dist_id(_song, _index);
            if (_next_dist_id == _dist_id) {
                return _index_addr;
            }
            _index_addr = distributions[_index].next_distributor;
            _index = _next_dist_id;
        }

        return address(0);
    }

    function find_dist_indexes(bytes32[] memory _songs, address _dist_addr) external view returns (address[] memory) {
        address[] memory insert_indexes = new address[](_songs.length);
        for (uint256 i = 0; i < _songs.length; i++) {
            insert_indexes[i] = _find_dist_index(_songs[i], _dist_addr);
        }

        return insert_indexes;
    }

    function _get_next_dist_id(bytes32 _song, bytes32 _dist_id) internal view returns (bytes32) {
        return gen_distribution_id(_song, distributions[_dist_id].next_distributor);
    }

    function _verify_index(bytes32 _song, bytes32 _index, uint256 _fee) internal view returns (bool) {
        return (_index == _song || distributions[_index].fee < _fee) &&
               (distributions[_index].next_distributor == END || distributions[_get_next_dist_id(_song, _index)].fee >= _fee);
    }

    function _remove_distribution(bytes32 _song, bytes32 _dist_id, bytes32 _index) internal {
        distributions[_index].next_distributor = distributions[_dist_id].next_distributor;
        delete distributions[_dist_id];
        songs[_song].distributors -= 1;
    }

    function _undistribute_all(bytes32 _song) internal {
        bytes32 _current_dist_id = _song;

        while (distributions[_current_dist_id].next_distributor != END) {
            bytes32 _next_dist_id = _get_next_dist_id(_song, _current_dist_id);
            delete distributions[_current_dist_id];
            _current_dist_id = _next_dist_id;
        }

        delete distributions[_current_dist_id];
    }

    function is_distributing(bytes32[] memory _songs, address _dist_addr) external view returns (bool[] memory) {        
        bool[] memory distributing = new bool[](_songs.length);
        for (uint256 i = 0; i < _songs.length; i++) {
            distributing[i] = distributions[gen_distribution_id(_songs[i], _dist_addr)].next_distributor != address(0);
        }

        return distributing; 
    }

    function get_distributors_length(bytes32 _song) external songExists(_song) view returns (uint256) {
        return songs[_song].distributors;
    }

    function get_distributors(bytes32 _song, address _start, uint256 _amount) external songExists(_song) view returns (Distribution_listing[] memory) {
        require(_amount > 0 && _amount <= songs[_song].distributors, "Indexes out of bounds");

        //Compute distribution id
        bytes32 _index;
        address _dist_addr;
        if (_start == address(0)) {
            _index = _get_next_dist_id(_song, _song);
            _dist_addr = distributions[_song].next_distributor;
        } else {
            _index = gen_distribution_id(_song, _start);
            _dist_addr = _start;
        }

        Distribution_listing[] memory lst = new Distribution_listing[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            require(_index != _song, "Index out of bounds");

            Distribution storage dist_obj = distributions[_index];
            require(dist_obj.next_distributor != address(0), "Song is not being distributed");
            lst[i] = Distribution_listing(_dist_addr, users[_dist_addr].server, dist_obj.fee);

            _index = _get_next_dist_id(_song, _index);
            _dist_addr = dist_obj.next_distributor;
        }

        return lst;
    }
    
    function get_rand_distributor(bytes32 _song, uint256 _seed) external songExists(_song) view returns (Distribution_listing memory) {
        if (songs[_song].distributors == 0) return Distribution_listing(address(0), "", 0);
        uint256 _rand = _seed % songs[_song].distributors;

        address _current_dist_addr = distributions[_song].next_distributor;
        bytes32 _current_dist_id = _get_next_dist_id(_song, _song);
        for (uint256 i = 0; i < _rand; i++) {
            _current_dist_addr = distributions[_current_dist_id].next_distributor;
            _current_dist_id = _get_next_dist_id(_song, _current_dist_id);
        }
        
        // return address and server information
        return Distribution_listing(_current_dist_addr, users[_current_dist_addr].server, distributions[_current_dist_id].fee);
    }

    function chunks_length(bytes32 _song) external songExists(_song) view returns (uint) {
        return songs[_song].chunks.length;
    }

    function get_chunks(bytes32 _song, uint256 _index, uint256 _amount, address _distributor) external userExists songExists(_song) {
        //Check distributor is valid,  and index is valid
        bytes32 _dist_id = gen_distribution_id(_song, _distributor);
        Distribution storage dist_obj = distributions[_dist_id];
        require(dist_obj.next_distributor != address(0), "Song is not being distributed");

        //Check indexes are valid
        Song storage song_obj = songs[_song];
        require(_index + _amount <= song_obj.chunks.length, "Indexes out of bounds");

        //Check user has enough funds
        uint256 total_price = (song_obj.price + dist_obj.fee) * _amount;
        require(users[msg.sender].balance >= total_price, "User do not have enough funds");

        // Distribute balance
        users[msg.sender].balance -= total_price;
        users[song_obj.rightholder].balance += song_obj.price * _amount;
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