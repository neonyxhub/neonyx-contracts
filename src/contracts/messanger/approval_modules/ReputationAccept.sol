// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ApprovalModule} from "./ApprovalModule.sol";

import {IIdentityManager} from "interfaces/did/IIdentityManager.sol";
import {IClubRegistry} from "interfaces/messanger/messanger_units/IClubRegistry.sol";

contract ReputationAccept is ApprovalModule {
    IClubRegistry public clubRegistry;

    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address user => EnumerableSet.AddressSet clubs) private whitelistedClubs;
    mapping(address user => mapping(address clubNxid => uint256 amount)) public requiredReputation;

    event RequiredReputationSet(address indexed userNxid, address indexed clubNxid, uint256 requiredReputation);
    event ClubRemoved(address indexed userNxid, address indexed _clubNxid);

    constructor(IClubRegistry _clubRegistry, IIdentityManager _identityManager)
        ApprovalModule("Reputation module.", _identityManager)
    {
        clubRegistry = _clubRegistry;
    }

    /**
     * @notice Sets a required reputation for specific club.
     * @param _userNxid The nxid of the user.
     * @param _clubNxid The nxid of the club to add.
     */
    function setRequiredReputation(address _userNxid, address _clubNxid, uint256 _requiredReputation)
        external
        onlyAdmin(_userNxid)
    {
        require(_requiredReputation != requiredReputation[_userNxid][_clubNxid], "Required reputation must change.");
        if (!whitelistedClubs[_userNxid].contains(_clubNxid)) {
            whitelistedClubs[_userNxid].add(_clubNxid);
        }

        requiredReputation[_userNxid][_clubNxid] = _requiredReputation;
        emit RequiredReputationSet(_userNxid, _clubNxid, _requiredReputation);
    }

    /**
     * @notice Removes a club from the whitelist.
     * @param _userNxid The nxid of the user.
     * @param _clubNxid The nxid of the club to remove.
     */
    function removeClub(address _userNxid, address _clubNxid) external onlyAdmin(_userNxid) {
        bool success = whitelistedClubs[_userNxid].remove(_clubNxid);
        require(success, "Club is not in list.");
        delete requiredReputation[_userNxid][_clubNxid];
        emit ClubRemoved(_userNxid, _clubNxid);
    }

    /**
     * @notice Get the list of clubs that a user is whitelisted for.
     * @param _nxid The nxid of the user.
     * @return An array of club addresses.
     */
    function getClubs(address _nxid) public view returns (address[] memory) {
        return whitelistedClubs[_nxid].values();
    }

    /// @inheritdoc ApprovalModule
    function isApproved(address _targetNxid, address _nxidToCheck) external view override returns (bool) {
        address[] memory clubs = getClubs(_targetNxid);
        for (uint256 i = 0; i < clubs.length; i++) {
            if (clubRegistry.getReputation(clubs[i], _nxidToCheck) >= requiredReputation[_targetNxid][clubs[i]]) {
                return true;
            }
        }
        return false;
    }
}
