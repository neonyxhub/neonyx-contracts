// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ApprovalModule} from "./ApprovalModule.sol";

import {IIdentityManager} from "interfaces/did/IIdentityManager.sol";
import {IClubRegistry} from "interfaces/messanger/messanger_units/IClubRegistry.sol";

contract MembershipAccept is ApprovalModule {
    IClubRegistry public clubRegistry;

    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address user => EnumerableSet.AddressSet clubs) private whitelistedClubs;

    event ClubWhitelisted(address indexed userNxid, address _clubNxid);
    event ClubRemoved(address indexed userNxid, address _clubNxid);

    constructor(IClubRegistry _clubRegistry, IIdentityManager _identityManager)
        ApprovalModule("Membership module.", _identityManager)
    {
        clubRegistry = _clubRegistry;
    }

    /**
     * @notice Adds a club to the whitelist.
     * @param _userNxid The nxid of the user.
     * @param _clubNxid The nxid of the club to add.
     */
    function addClub(address _userNxid, address _clubNxid) external onlyAdmin(_userNxid) {
        bool success = whitelistedClubs[_userNxid].add(_clubNxid);
        require(success, "Club already added.");
        emit ClubWhitelisted(_userNxid, _clubNxid);
    }

    /**
     * @notice Removes a club from the whitelist.
     * @param _userNxid The nxid of the user.
     * @param _clubNxid The nxid of the club to remove.
     */
    function removeClub(address _userNxid, address _clubNxid) external onlyAdmin(_userNxid) {
        bool success = whitelistedClubs[_userNxid].remove(_clubNxid);
        require(success, "Club is not in list.");
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
            if (clubRegistry.isMember(clubs[i], _nxidToCheck)) {
                return true;
            }
        }
        return false;
    }
}
