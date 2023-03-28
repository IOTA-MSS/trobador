// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../evm-library/ISC.sol";

/**
 * @title TangleTunes: backend logic for a P2P music streaming application
 * @author Daniel Melero
 */
interface TangleTunesI {

    struct User {
        bool exists;
        string username;
        string description;
        string server; // TODO: separate into ip, port, public key
        uint256 balance;
        bool is_validator;
        bytes32[] author_of;
        bytes32[] holds_rights_to;
        bytes32[] validates;
    }

    struct Song {
        bool exists;
        address author;
        address rightholder;
        address validator;
        string name;
        uint256 price;
        uint256 length;
        uint256 duration;
        bytes32[] chunks;
        address[] distributors; //TODO: sorted data structure
        //TODO: validator address (after MVP Optional)
    }

    struct Distribution {
        bool exists;
        uint256 index;
        uint256 fee;
        //TODO: Staking value (after MVP)
    }

    struct Song_listing {
        bytes32 song_id;
        string song_name;
        string author_name;
        uint price;
        uint length;
        uint duration;
    }

    /**
     * @notice provides deployer's address
     * @return deployer's address
     */
    function owner() external view returns (address);

    /**
     * @notice provides the amount of songs available
     * @return amount of songs
     */
    function song_list_length() external view returns (uint256);

    /**
     * @notice provides all displayable information of a given amount of songs
     * @dev a song has been removed and should not be displayed if its id is 0x00
     * @param _index in list of songs
     * @param _amount of songs returned
     * @return list of songs
     */
    function get_songs(uint _index, uint _amount) external view returns (Song_listing[] memory);

    /**
     * @notice provides account linked to a given address
     * @param _user address
     * @return [<exists>,<username>,<description>,<server>,<balance>,<is_validator>]
     */
    function users(address _user) external view returns (bool, string memory, string memory, string memory, uint, bool);

    //TODO
    function get_author_of_length(address _user) external view returns (uint);

    //TODO
    function get_author_of_songs(address _user, uint _index, uint _amount) external view returns (Song_listing[] memory);

    //TODO
    function get_author_of_song_id(address _user, uint _index) external view returns (bytes32);

    //TODO
    function get_holds_rights_to_length(address _user) external view returns (uint);

    //TODO
    function get_holds_rights_to_songs(address _user, uint _index, uint _amount) external view returns (Song_listing[] memory);

    //TODO
    function get_holds_rights_to_song_id(address _user, uint _index) external view returns (bytes32);

    //TODO
    function get_validates_length(address _user) external view returns (uint);

    //TODO
    function get_validates_songs(address _user, uint _index, uint _amount) external view returns (Song_listing[] memory);

    //TODO
    function get_validates_song_id(address _user, uint _index) external view returns (bytes32);

    /**
     * @notice provides metadata of a given song
     * @dev does not provide the list of chunks or the list of distributors
     * @param _song identification value
     * @return [<exists>,<author>,<rightholder>,<validator>,<name>,<price>,<length>,<duration>]
     */
    function songs(bytes32 _song) external view returns (bool, address, address, address, string memory, uint, uint, uint);

    /**
     * @notice provides metadata about a given distribution
     * @param _distribution identification value
     * @return [<exists>,<index>,<fee>]
     */
    function distributions(bytes32 _distribution) external view returns (bool, uint, uint);

    /**
     * @notice provides song identification value of a given index
     * @param _index in the list of songs (starting at 0)
     * @return song id
     */
    function song_list(uint _index) external view returns (bytes32);

    /**
     * @notice modifies validator status of the given account
     * @dev only accessible to the smart contract deployer
     * @param _validator address must be linked to an active account
     */
    function manage_validators(address _validator) external;

    /**
     * @notice creates active account linked to the sender address
     * @param _name account name
     * @param _desc account description
     */
    function create_user(string memory _name, string memory _desc) external;

    /**
     * @notice removes all user information linked to the sender address
     * @dev also removes all music linked to the account
     */
    function delete_user() external;

    /**
     * @notice changes description in sender adress' account
     * @param _desc account description
     */
    function edit_description(string memory _desc) external;

    /**
     * @notice changes server information in sender address' account
     * @dev url string contains: <ip>:<port>:<pub_key_cert>
     * @param _server details (TODO: MIGHT CHANGE)
     */
    function edit_server_info(string memory _server) external;

    /**
     * @notice adds value to the sender address' account
     */
    function deposit() external payable;

    //TODO
    function withdraw_to_chain(uint _amount) external;

    /**
     * @notice sends account's balance to a given address in the L1 ledger
     * @param _amount to be withdrawn
     * @param _target address in the L1 ledger
     */
    function withdraw_to_tangle(uint64 _amount, L1Address memory _target) external;

    /**
     * @notice uploads song's metadata to the platform
     * @dev only accessible to validators
     * @param _name of the song
     * @param _price per chunk
     * @param _length of the file in bytes
     * @param _duration of the song in seconds
     * @param _chunks list of the keccak hash value of each chunk
     * @param _nonce for uploaded songs of author
     * @param _signature hashed value of all previous parameters signed by the rightholder
     */
    function upload_song(address _author, string memory _name, uint _price, uint _length, uint _duration, bytes32[] memory _chunks, uint _nonce, bytes memory _signature) external;

    //TODO:
    function delete_song(bytes32 _song) external;

    /**
     * @notice generates the identification value of a song
     * @param _name of the song
     * @param _author of the song
     * @return song id
     */
    function gen_song_id(string memory _name, address _author) external pure returns (bytes32);

    /**
     * @notice changes the song's price
     * @dev only accessible to the song's author
     * @param _song identification value
     * @param _price per chunk
     */
    function edit_price(bytes32 _song, uint _price) external;

    /**
     * @notice generates the identification value of a distribution
     * @param _song identification value
     * @param _distributor address
     */
    function gen_distribution_id(bytes32 _song, address _distributor) external pure returns (bytes32);

    /**
     * @notice signs up for distribution on a given song
     * @param _song identification value
     * @param _fee per chunk
     */
    function distribute(bytes32 _song, uint _fee) external;

    /**
     * @notice changes the distribution fee on a given song
     * @param _song identification value
     * @param _fee per chunk
     */
    function edit_fee(bytes32 _song, uint _fee) external;

    /**
     * @notice unlist for distribution on a given song
     * @param _song identification value
     */
    function undistribute(bytes32 _song) external;

    /**
     * @notice provides a random distributor for a given song
     * @param _song identification value
     * @return the address of a distributor of the given song and its server information
     */
    function get_rand_distributor(bytes32 _song) external view returns (address, string memory);
    //TODO: provide based on distribution fee and/or staking value (+ some randomness)
    //TODO: get_distributor(bytes32 _song, uint _amount, uint _region) external view returns (address[]);

    /**
     * @notice provides the amount of chunks in a given song
     * @param _song identification value
     * @return amount of chunks
     */
    function chunks_length(bytes32 _song) external view returns (uint);

    /**
     * @notice pay author and distributor for a given amount of consecutive chunks
     * @param _song identification value
     * @param _index of the first chunk
     * @param _amount of consecutive chunks
     * @param _distributor address
     */
    function get_chunks(bytes32 _song, uint _index, uint _amount, address _distributor) external;

    /**
     * @notice provides a given amount of chunks to locally check their authenticity
     * @param _song identification value
     * @param _index of the chunk
     * @param _amount keccak hash value of the data
     * @return list of requested chunks from a given song
     */
    function check_chunks(bytes32 _song, uint _index, uint _amount) external view returns (bytes32[] memory);
}