// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../evm-library/ISCTypes.sol";

/**
 * @title TangleTunes: backend logic for a P2P music streaming application
 * @author Daniel Melero
 */
interface TangleTunes {
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
     * @notice adds value to the sender address' account
     */
    function deposit() external payable;

    /**
     * @notice sends account's balance to a given address in the L1 ledger
     * @param _amount to be withdrawn
     * @param _target address in the L1 ledger
     */
    function withdraw(uint256 _amount, L1Address memory _target) external;

    /**
     * @notice uploads song's metadata to the platform
     * @dev only accessible to validators
     * @param _name of the song
     * @param _price per chunk
     * @param _length of the file in bytes
     * @param _duration of the song in seconds
     * @param _chunks list of the keccak hash value of each chunk
     */
    function upload_song(string memory _name, uint _price, uint _length, uint _duration, bytes32[] memory _chunks) external;

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
    function edit_price(bytes32 _song, uint256 _price) external;

    /**
     * @notice changes server information in sender address' account
     * @dev url string contains: <ip>:<port>:<pub_key_cert>
     * @param _server details
     */
    function edit_server_info(string memory _server) external;

    /**
     * @notice signs up for distribution on a given song
     * @param _song identification value
     */
    function distribute(bytes32 _song) external;

    /**
     * @notice unlist for distribution on a given song
     * @param _song identification value
     */
    function undistribute(bytes32 _song) external;

    /**
     * @notice checks if a given account is currently distributing a given song
     * @param _song identification value
     * @param _distributor address
     * @return true if it is listed as a distributor on the given song, false if not
     */
    function is_distributing(bytes32 _song, address _distributor) external view returns (bool);

    /**
     * @notice creates a streaming session for the given song
     * @dev the sender address' account must have enough funds to stream the entire song
     * @param _song identification value
     * @param _distributor address
     */
    function create_session(bytes32 _song, address _distributor) external;

    /**
     * @notice provides a random distributor for a given song
     * @param _song identification value
     * @return the address of an account listed as distributor of the given song
     */
    function get_rand_distributor(bytes32 _song) external view returns (address);

    /**
     * @notice generates a session identification value
     * @param _listener address
     * @param _distributor address
     * @param _song identification value
     * @return session id
     */
    function gen_session_id(address _listener, address _distributor, bytes32 _song) external pure returns (bytes32);

    /**
     * @notice provides the amount of chunks in a given song
     * @param _song identification value
     * @return amount of chunks
     */
    function chunks_length(bytes32 _song) external view returns (uint);
    function get_chunk(bytes32 session, uint chunk_index) external;
    function check_chunk(bytes32 song, uint index, bytes32 _chunk) external view returns (bool);
    function is_chunk_paid(bytes32 session, uint index) external view returns (bool);
    function close_session(bytes32 session) external;
}