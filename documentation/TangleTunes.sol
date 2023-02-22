// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../evm-library/ISCTypes.sol";

/**
 * @title TangleTunes: backend logic for a P2P music streaming application
 * @author Daniel Melero
 */
interface TangleTunes {
    
    struct User {
        bool exists;
        string username;
        string description;
        string server;
        uint balance;
        bool is_validator;
    }

    struct Song {
        bool exists;
        address author;
        string name;
        uint price;
        uint length;
        uint duration;
        bytes32[] chunks;
        address[] distributors;
    }

    struct Distribution {
        bool exists;
        uint index;
        uint fee;
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
     * @return account details
     */
    function users(address _user) external view returns (User memory);

    /**
     * @notice provides metadata of a given song
     * @dev does not provide the list of chunks or the list of distributors
     * @param _song identification value
     * @return song details
     */
    function songs(bytes32 _song) external view returns (Song memory);

    /**
     * @notice provides metadata about a given distribution
     * @param _distribution identification value
     * @return distribution details
     */
    function distributions(bytes32 _distribution) external view returns (Distribution memory);

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

    /**
     * @notice sends account's balance to a given address in the L1 ledger
     * @param _amount to be withdrawn
     * @param _target address in the L1 ledger
     */
    function withdraw(uint _amount, L1Address memory _target) external;

    /**
     * @notice uploads song's metadata to the platform
     * @dev only accessible to validators
     * @param _name of the song
     * @param _price per chunk
     * @param _length of the file in bytes
     * @param _duration of the song in seconds
     * @param _chunks list of the keccak hash value of each chunk
     */
    function upload_song(address _author, string memory _name, uint _price, uint _length, uint _duration, bytes32[] memory _chunks) external;

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
     * @notice unlist for distribution on a given song
     * @param _song identification value
     */
    function undistribute(bytes32 _song) external;

    /**
     * TODO: provide based on distribution fee and/or staking value (+ some randomness)
     * @notice provides a random distributor for a given song
     * @param _song identification value
     * @return the address of an account listed as distributor of the given song
     */
    function get_rand_distributor(bytes32 _song) external view returns (address);
    // get_distributor(bytes32 _song, uint index, uint region) external view returns (address[]);

    /**
     * @notice provides the amount of chunks in a given song
     * @param _song identification value
     * @return amount of chunks
     */
    function chunks_length(bytes32 _song) external view returns (uint);

    /**
     * @notice pay author and distributor for a given chunk
     * @param _song identification value
     * @param _index of the chunk
     * @param _distributor address
     */
    function get_chunk(bytes32 _song, uint _index, address _distributor) external;

    /**
     * @notice check authenticity of a given chunk
     * @param _song identification value
     * @param _index of the chunk
     * @param _chunk keccak hash value of the data
     * @return true if the data received is authentic, false otherwise
     */
    function check_chunk(bytes32 _song, uint _index, bytes32 _chunk) external view returns (bool);
}