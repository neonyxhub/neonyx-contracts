// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {IIdentityManager} from "interfaces/did/IIdentityManager.sol";

contract IdentityChecker {
    IIdentityManager public immutable identityManager;

    constructor(IIdentityManager _identityManager) {
        identityManager = IIdentityManager(_identityManager);
    }

    /**
     * @dev Modifier to restrict access to only the owner of the user or an contract admin.
     * @param _nxid The nxid of the user.
     */
    modifier onlyAdmin(address _nxid) {
        AccessControl userContract = AccessControl(_nxid);
        require(
            msg.sender == _nxid // if sender is nxid itself
                || msg.sender == address(identityManager) // if sender is identityManager then transaction is authorized via signature
                || identityManager.onchainControllers(_nxid, msg.sender) >= block.timestamp, // if sender is nxid controller
            "You are not an owner."
        );
        _;
    }
}
