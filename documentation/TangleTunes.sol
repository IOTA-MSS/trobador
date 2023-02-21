// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
/**
 * @title TangleTunes: backend logic for a P2P music streaming application
 * @author Daniel Melero
 */
interface TangleTunes {
    function manage_validators(address _val) external;
    function create_user(string memory _name, string memory _desc) external;
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function upload_song(string memory _name, uint _price, uint _length, uint _duration, bytes32[] memory _chunks) external;
    function gen_song_id(string memory _name, address _sender) external pure returns (bytes32);
    function manage_validation(bytes32 song) external;
    function edit_price(bytes32 song, uint256 _price) external;
    function edit_url(string memory url) external ;
    function distribute(bytes32 song) external;
    function undistribute(bytes32 song) external;
    function is_distributing(bytes32 song, address distributor) external view returns (bool);
    function create_session(bytes32 _song, address _distributor) external;
    function compute_distributor_fee(uint price) external view returns (uint);
    function get_rand_distributor(bytes32 _song) external view returns (address);
    function gen_session_id(address _sender, address _distributor, bytes32 _song) external pure returns (bytes32);
    function chunks_length(bytes32 song) external view returns (uint);
    function get_chunk(bytes32 session, uint chunk_index) external;
    function check_chunk(bytes32 song, uint index, bytes32 _chunk) external view returns (bool);
    function is_chunk_paid(bytes32 session, uint index) external view returns (bool);
    function close_session(bytes32 session) external;
}