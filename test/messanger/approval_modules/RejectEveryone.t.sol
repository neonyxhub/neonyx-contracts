// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {IdentityManager} from "contracts/did/IdentityManager.sol";
import {RejectEveryone} from "contracts/messanger/approval_modules/RejectEveryone.sol";

contract RejectEveryoneTest is Test {
    RejectEveryone internal module;
    IdentityManager internal identityManager;

    function setUp() public {
        identityManager = new IdentityManager();
        module = new RejectEveryone(identityManager);
    }

    function test_IsApproved(address targetNxid, address nxidToCheck) external {
        bool result = module.isApproved(targetNxid, nxidToCheck);
        assertFalse(result);
    }
}
