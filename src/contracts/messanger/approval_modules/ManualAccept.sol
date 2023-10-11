// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ApprovalModule} from "./ApprovalModule.sol";

import {IIdentityManager} from "interfaces/did/IIdentityManager.sol";

/**
 * @title ManualAccept
 * @notice A contract that extends the ApprovalModule and allows manual approval of addresses.
 */
contract ManualAccept is ApprovalModule {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address user => EnumerableSet.AddressSet) private approved;

    event AddressAdded(address indexed userNxid, address indexed addedNxid);
    event AddressRemoved(address indexed userNxid, address indexed removedNxid);

    constructor(IIdentityManager _identityManager) ApprovalModule("Manual accept.", _identityManager) {}

    /**
     * @notice Adds an address to the list of approved addresses for a specific user.
     * @param _userNxid The nxid of the user.
     * @param _nxidToAdd The nxid to add to the approved addresses list.
     */
    function addAddress(address _userNxid, address _nxidToAdd) external onlyAdmin(_userNxid) {
        bool success = approved[_userNxid].add(_nxidToAdd);
        require(success, "Address is already in list.");
        emit AddressAdded(_userNxid, _nxidToAdd);
    }

    /**
     * @notice Removes an address from the list of approved addresses for a specific user.
     * @param _userNxid The address of the user.
     * @param _nxidToRemove The address to remove from the approved addresses list.
     */
    function removeAddress(address _userNxid, address _nxidToRemove) external onlyAdmin(_userNxid) {
        bool success = approved[_userNxid].remove(_nxidToRemove);
        require(success, "Address is not in list.");
        emit AddressRemoved(_userNxid, _nxidToRemove);
    }

    /**
     * @notice Returns the list of approved addresses for a specific user.
     * @param _userNxid The address of the user.
     * @return An array of approved addresses.
     */
    function getAddresses(address _userNxid) external view returns (address[] memory) {
        return approved[_userNxid].values();
    }

    /// @inheritdoc ApprovalModule
    function isApproved(address _targetNxid, address _nxidToCheck) external view override returns (bool) {
        return approved[_targetNxid].contains(_nxidToCheck);
    }
}
