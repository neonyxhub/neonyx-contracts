// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IEAS, AttestationRequest, RevocationRequest} from "eas-contracts/IEAS.sol";

import {IdentityChecker} from "contracts/did/IdentityChecker.sol";

import {IIdentityManager} from "interfaces/did/IIdentityManager.sol";
import {IModuleStorage} from "interfaces/messanger/IModuleStorage.sol";
import {IClubRegistry, Club} from "interfaces/messanger/messanger_units/IClubRegistry.sol";

/**
 * @title ClubRegistry
 * @notice This contract manages club memberships and reputations using Ethereum Attestation Service.
 */
contract ClubRegistry is IClubRegistry, IdentityChecker {
    IEAS public immutable eas;
    IModuleStorage public immutable moduleStorage;
    bytes32 public immutable membershipSchema;
    bytes32 public immutable reputationSchema;

    mapping(address clubNxid => Club clubData) private clubs;
    mapping(address clubNxid => mapping(address senderNxid => mapping(address receiverNxid => bytes32 attestUid)))
        public reputationAttests;
    mapping(address clubNxid => mapping(address memberNxid => bytes32 attestUid)) public membership;
    mapping(address clubNxid => mapping(address memberNxid => uint256 reputationAmount)) private reputation;

    constructor(
        IModuleStorage _moduleStorage,
        IEAS _eas,
        IIdentityManager _identityManager,
        bytes32 _membershipSchema,
        bytes32 _reputationSchema
    ) IdentityChecker(_identityManager) {
        eas = _eas;
        membershipSchema = _membershipSchema;
        reputationSchema = _reputationSchema;
        moduleStorage = _moduleStorage;
    }

    /// @inheritdoc IClubRegistry
    function getClub(address _clubNxid) external view returns (Club memory) {
        return clubs[_clubNxid];
    }

    /**
     * @dev Modifier to check if an attestation does not exist.
     * @param _attestationUid The unique identifier of the attestation.
     */
    modifier attestationNotExist(bytes32 _attestationUid) {
        // if _attestationUid is EMPTY_UID or attestation already revoked then attestation is not exist.
        require(
            _attestationUid == bytes32(0) || eas.getAttestation(_attestationUid).revocationTime != 0,
            "Attestation already exist."
        );
        _;
    }

    /**
     * @dev Modifier to check if an attestation exist.
     * @param _attestationUid The unique identifier of the attestation.
     */
    modifier attestationExist(bytes32 _attestationUid) {
        // We don't need to check creation timestamp because _attestationUid can be passed only internally from mappings.
        // It's not possible to write attestation which is not exist to mappings.
        // That's why we only check if _attestationUid is not EMPTY_UID and is not revoked.
        require(
            _attestationUid != bytes32(0) && eas.getAttestation(_attestationUid).revocationTime == 0,
            "Attestation is not exist."
        );
        _;
    }

    /**
     * @dev Modifier to check if reputation is allowed for a club.
     * @param _clubNxid The NXID of the club.
     */
    modifier reputationExist(address _clubNxid) {
        require(clubs[_clubNxid].onchainReputationAllowed, "Reputation is not allowed.");
        _;
    }

    /**
     * @dev Modifier to check if membership is allowed for a club.
     * @param _clubNxid The NXID of the club.
     */
    modifier membershipExist(address _clubNxid) {
        require(clubs[_clubNxid].onchainMembershipAllowed, "Membership is not allowed.");
        _;
    }

    modifier onlyMember(address _clubNxid, address _userNxid) {
        require(isMember(_clubNxid, _userNxid), "User is not club member.");
        _;
    }

    /// @inheritdoc IClubRegistry
    function isMember(address _clubNxid, address _userNxid) public view returns (bool) {
        bytes32 _attestationUid = membership[_clubNxid][_userNxid];
        return _attestationUid != bytes32(0) && eas.getAttestation(_attestationUid).revocationTime == 0;
    }

    /// @inheritdoc IClubRegistry
    function allowReputation(address _clubNxid) external onlyAdmin(_clubNxid) membershipExist(_clubNxid) {
        require(!clubs[_clubNxid].onchainReputationAllowed, "Reputation already allowed.");
        clubs[_clubNxid].onchainReputationAllowed = true;
        emit ReputationAllowed(_clubNxid);
    }

    /// @inheritdoc IClubRegistry
    function allowMembership(address _clubNxid) external onlyAdmin(_clubNxid) {
        require(!clubs[_clubNxid].onchainMembershipAllowed, "Membership already allowed.");
        clubs[_clubNxid].onchainMembershipAllowed = true;
        emit MembershipAllowed(_clubNxid);
    }

    /// @inheritdoc IClubRegistry
    function getReputation(address _clubNxid, address _memberNxid) public view returns (uint256) {
        if (isMember(_clubNxid, _memberNxid)) {
            return reputation[_clubNxid][_memberNxid];
        }
        return 0;
    }

    /// @inheritdoc IClubRegistry
    function plusReputation(address _senderNxid, address _clubNxid, address _receiverNxid)
        external
        onlyAdmin(_senderNxid)
        reputationExist(_clubNxid)
        attestationNotExist(reputationAttests[_clubNxid][_senderNxid][_receiverNxid])
        onlyMember(_clubNxid, _senderNxid)
        onlyMember(_clubNxid, _receiverNxid)
    {
        AttestationRequest memory _reputationAttest;
        _reputationAttest.schema = reputationSchema;
        _reputationAttest.data.revocable = true;
        _reputationAttest.data.data = abi.encode(_clubNxid, _senderNxid, _receiverNxid);

        bytes32 _attestUid = eas.attest(_reputationAttest);
        reputationAttests[_clubNxid][_senderNxid][_receiverNxid] = _attestUid;
        reputation[_clubNxid][_receiverNxid]++;
        emit ReputationAdded(_clubNxid, _senderNxid, _receiverNxid);
    }

    /// @inheritdoc IClubRegistry
    function minusReputation(address _senderNxid, address _clubNxid, address _receiverNxid)
        external
        onlyAdmin(_senderNxid)
        attestationExist(reputationAttests[_clubNxid][_senderNxid][_receiverNxid])
    {
        RevocationRequest memory _revocationAttest;
        _revocationAttest.schema = reputationSchema;
        _revocationAttest.data.uid = reputationAttests[_clubNxid][_senderNxid][_receiverNxid];
        eas.revoke(_revocationAttest);
        delete reputationAttests[_clubNxid][_senderNxid][_receiverNxid];
        reputation[_clubNxid][_receiverNxid]--;
        emit ReputationRemoved(_clubNxid, _senderNxid, _receiverNxid);
    }

    /**
     * @dev Internal function to add a member to a club.
     * @param _memberNxid The NXID of the club member.
     * @param _clubNxid The NXID of the club.
     */
    function _addMember(address _memberNxid, address _clubNxid)
        internal
        membershipExist(_clubNxid)
        attestationNotExist(membership[_clubNxid][_memberNxid])
    {
        AttestationRequest memory membershipAttest;
        membershipAttest.schema = membershipSchema;
        membershipAttest.data.revocable = true;
        membershipAttest.data.data = abi.encode(_clubNxid, _memberNxid);

        bytes32 _attestUid = eas.attest(membershipAttest);
        membership[_clubNxid][_memberNxid] = _attestUid;
        emit MemberAdded(_clubNxid, _memberNxid);
    }

    /// @inheritdoc IClubRegistry
    function addMember(address _clubNxid, address _memberNxid) external onlyAdmin(_clubNxid) {
        _addMember(_memberNxid, _clubNxid);
    }

    /// @inheritdoc IClubRegistry
    function joinClub(address _memberNxid, address _clubNxid) external onlyAdmin(_memberNxid) {
        // check if club modules have approved the new user's membership
        moduleStorage.checkApproval(_clubNxid, _memberNxid);
        _addMember(_memberNxid, _clubNxid);
    }
}
