// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ApprovalModule} from "contracts/messanger/approval_modules/ApprovalModule.sol";
import {IIdentityManager} from "interfaces/did/IIdentityManager.sol";

/**
 * @title RejectEveryone
 * @dev A contract that extends the ApprovalModule and rejects all address.
 */
contract RejectEveryone is ApprovalModule {
    constructor(IIdentityManager _identityManager) ApprovalModule("Reject everyone", _identityManager) {}

    function isApproved(address, /* _targetNxid */ address /* _nxidToCheck */ )
        external
        pure
        override
        returns (bool result)
    {}
}
