// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct Club {
    bool onchainMembershipAllowed;
    bool onchainReputationAllowed;
}

interface IClubRegistry {
    event ReputationAdded(address indexed _clubNxid, address indexed _senderNxid, address indexed _receiverNxid);
    event ReputationRemoved(address indexed _clubNxid, address indexed _senderNxid, address indexed _receiverNxid);
    event ReputationAllowed(address indexed _clubNxid);
    event MembershipAllowed(address indexed _clubNxid);
    event MemberAdded(address indexed _clubNxid, address indexed _memberNxid);

    function getClub(address _clubNxid) external view returns (Club memory);

    function reputationAttests(address _clubNxid, address _senderNxid, address _receiverNxid)
        external
        view
        returns (bytes32);

    function membership(address _clubNxid, address _memberNxid) external view returns (bytes32);

    /**
     * @notice Function to allow onchain reputation for a club.
     * @param _clubNxid The NXID of the club.
     */
    function allowReputation(address _clubNxid) external;

    /**
     * @notice Function to allow onchain membership for a club.
     * @param _clubNxid The NXID of the club.
     */
    function allowMembership(address _clubNxid) external;

    /**
     * @notice Function check is _memberNxid a club member.
     * @param _clubNxid The NXID of the club.
     * @param _userNxid The NXID of the user to check.
     * @return is user club member or not
     */
    function isMember(address _clubNxid, address _userNxid) external view returns (bool);

    /**
     * @notice Function to get _userNxid reputation in a club.
     * @param _clubNxid The NXID of the club.
     * @param _userNxid The NXID of the user to check.
     * @return reputation in club.
     */
    function getReputation(address _clubNxid, address _userNxid) external view returns (uint256);

    /**
     * @notice Function to increase reputation for a member in a club.
     * @param _senderNxid The NXID of the reputation sender.
     * @param _clubNxid The NXID of the club.
     * @param _receiverNxid The NXID of the reputation receiver.
     */
    function plusReputation(address _senderNxid, address _clubNxid, address _receiverNxid) external;

    /**
     * @notice Function to decrease reputation for a member in a club.
     * @param _senderNxid The NXID of the reputation sender.
     * @param _clubNxid The NXID of the club.
     * @param _receiverNxid The NXID of the reputation receiver.
     */
    function minusReputation(address _senderNxid, address _clubNxid, address _receiverNxid) external;

    /**
     * @notice Function to add a member to a club.
     * @param _clubNxid The NXID of the club.
     * @param _memberNxid The NXID of the club member.
     */
    function addMember(address _clubNxid, address _memberNxid) external;

    /**
     * @notice Function for a member to join a club, subject to approval by the IModuleStorage.
     * @param _memberNxid The NXID of the club member.
     * @param _clubNxid The NXID of the club.
     */
    function joinClub(address _memberNxid, address _clubNxid) external;
}
