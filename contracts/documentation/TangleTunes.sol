// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
 * Copyright (c) 2023 Daniel Melero
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Copyright (c) 2023 Daniel Melero
 * University of Twente
 */

import "../evm-library/ISC.sol";

/**
 * @title TangleTunes: backend logic for a P2P music streaming application
 */
interface TangleTunesI {

    struct User {
        bool exists;
        string username;
        string description;
        string server; // TODO: separate into ip, port, public key
        uint balance;
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
        uint price;
        uint length;
        uint duration;
        uint distributors;
        bytes32[] chunks;
    }

    struct Distribution {
        uint fee;
        address next_distributor;
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

    struct Distribution_listing {
        address distributor;
        string server;
        uint fee;
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
    function song_list_length() external view returns (uint);

    /**
     * @notice provides all displayable information of a given amount of songs
     * @dev a song has been removed and should not be displayed if its id is 0x00
     * @dev repeated ocurrences of the same song may appear
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

    /**
     * @notice provides the amount of songs the user is author of
     * @return amount of songs
     */
    function get_author_of_length(address _user) external view returns (uint);

    /**
     * @notice provides all displayable information of a given amount of songs the user is author of
     * @dev a song has been removed and should not be displayed if its id is 0x00
     * @dev repeated ocurrences of the same song may appear
     * @param _index in list of songs
     * @param _amount of songs returned
     * @return list of songs
     */
    function get_author_of_songs(address _user, uint _index, uint _amount) external view returns (Song_listing[] memory);

    /**
     * @notice provides song identification value of a given index in the list of songs the user is author of
     * @dev id may correspond to a song that no longer exists
     * @param _index in the list of songs (starting at 0)
     * @return song id
     */
    function get_author_of_song_id(address _user, uint _index) external view returns (bytes32);

    /**
     * @notice provides the amount of songs the user holds the rigths to
     * @return amount of songs
     */
    function get_holds_rights_to_length(address _user) external view returns (uint);

    /**
     * @notice provides all displayable information of a given amount of songs the user holds the rigths to
     * @dev a song has been removed and should not be displayed if its id is 0x00
     * @dev repeated ocurrences of the same song may appear
     * @param _index in list of songs
     * @param _amount of songs returned
     * @return list of songs
     */
    function get_holds_rights_to_songs(address _user, uint _index, uint _amount) external view returns (Song_listing[] memory);

    /**
     * @notice provides song identification value of a given index in the list of songs the user holds the rigths to
     * @dev id may correspond to a song that no longer exists
     * @param _index in the list of songs (starting at 0)
     * @return song id
     */
    function get_holds_rights_to_song_id(address _user, uint _index) external view returns (bytes32);

    /**
     * @notice provides the amount of songs the user has validated
     * @return amount of songs
     */
    function get_validates_length(address _user) external view returns (uint);

    /**
     * @notice provides all displayable information of a given amount of songs the user has validated
     * @dev a song has been removed and should not be displayed if its id is 0x00
     * @dev repeated ocurrences of the same song may appear
     * @param _index in list of songs
     * @param _amount of songs returned
     * @return list of songs
     */
    function get_validates_songs(address _user, uint _index, uint _amount) external view returns (Song_listing[] memory);

    /**
     * @notice provides song identification value of a given index in the list of songs the user has validated
     * @dev id may correspond to a song that no longer exists
     * @param _index in the list of songs (starting at 0)
     * @return song id
     */
    function get_validates_song_id(address _user, uint _index) external view returns (bytes32);

    /**
     * @notice provides metadata of a given song
     * @dev does not provide the list of chunks or the list of distributors
     * @param _song identification value
     * @return [<exists>,<author>,<rightholder>,<validator>,<name>,<price>,<length>,<duration>,<distributors>]
     */
    function songs(bytes32 _song) external view returns (bool, address, address, address, string memory, uint, uint, uint, uint);

    /**
     * @notice provides metadata about a given distribution
     * @param _distribution identification value
     * @return [<exists>,<index>,<fee>]
     */
    function distributions(bytes32 _distribution) external view returns (uint, address);

    /**
     * @notice provides song identification value of a given index
     * @dev id may correspond to a song that no longer exists
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
     * @param _server details
     */
    function edit_server_info(string memory _server) external;

    /**
     * @notice adds value to the sender address' account
     * @dev the value added is equal to the value of the transaction
     */
    function deposit() external payable;

    /**
     * @notice sends account's balance to its L2 wallet address
     * @param _amount to be withdrawn
     */
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

    /**
     * @notice remove all information about a given song from the smart contract storage
     * @dev only accessible to the song's validator and rightholder
     * @param _song identification value
     */
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
     * @dev only accessible to the song's rightholder
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
     * @notice signs up for distribution or updates fee on a given song
     * @dev _index_addr is equal to address(0) if distributor is the head of the list
     * @param _songs list of song identification values
     * @param _fees per chunk per song
     * @param _dist_index_addresses addresses of the previous distributors of existing distribution
     * @param _insert_index_addresses addresses of the previous distributors where to insert new distribution
     */
    function distribute(bytes32[] memory _songs, uint[] memory _fees, address[] memory _dist_index_addresses, address[] memory _insert_index_addresses) external;

    /**
     * @notice unlist for distribution on a given list of song
     * @dev _index_addr is equal to address(0) if distributor is the head of the list
     * @param _songs list of song identification values
     * @param _index_addresses addresses of the previous distributors per song
     */
    function undistribute(bytes32[] memory _songs, address[] memory _index_addresses) external;

    /**
     * @notice finds the addresses of the distributors after which it should be inserted based on the given fees
     * @param _songs list of song identification values
     * @param _fees list of fees per chunk per song
     * @return list of indexes per song
     */
    function find_insert_indexes(bytes32[] memory _songs, uint[] memory _fees) external view returns (address[] memory);

    /**
     * @notice finds the index in the distribution list where the given distributor can be found
     * @param _songs list of song identification values
     * @param _dist_addr distributor
     * @return list of indexes per song
     */
    function find_dist_indexes(bytes32[] memory _songs, address _dist_addr) external view returns (address[] memory);

    /**
     * @notice checks that the given distributor is on the songs' distribution lists
     * @param _songs list of song identification values
     * @param _dist_addr distributor
     * @return list of booleans per song
     */
    function is_distributing(bytes32[] memory _songs, address _dist_addr) external view returns (bool[] memory);

    /**
     * @notice provides the amount of distributors for a given song
     * @param _song identification value
     * @return amount of distributors
     */
    function get_distributors_length(bytes32 _song) external view returns (uint);

    /**
     * @notice provides a given amount of distributors for a given song
     * @param _song identification value
     * @param _start distributor at which to start traversing
     * @param _amount of distributos
     * @return list of addressess, servers and fees per distributor
     */
    function get_distributors(bytes32 _song, address _start, uint _amount) external view returns (Distribution_listing[] memory);

    /**
     * @notice provides a random distributor for a given song
     * @param _song identification value
     * @param _seed source of randomness [0, 2^256]
     * @return the address of a distributor, its server information and its fee
     */
    function get_rand_distributor(bytes32 _song, uint _seed) external view returns (Distribution_listing memory);
 
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