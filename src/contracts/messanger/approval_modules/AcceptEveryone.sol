// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ApprovalModule} from "./ApprovalModule.sol";

import {IIdentityManager} from "interfaces/did/IIdentityManager.sol";

/**
 * @title AcceptEveryone
 * @notice A contract that implements the ApprovalModule interface and approves all address.
 */
contract AcceptEveryone is ApprovalModule {
    constructor(IIdentityManager _identityManager) ApprovalModule("Accept everyone", _identityManager) {}

    /// @inheritdoc ApprovalModule
    function isApproved(address, /* _targetNxid */ address /* _nxidToCheck */ ) external pure override returns (bool) {
        return true;
    }
}
