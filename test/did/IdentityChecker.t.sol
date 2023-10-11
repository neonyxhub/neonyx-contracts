// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IdentityCheckerHarness} from "./IdentityCheckerHarness.sol";
import {IdentityManager} from "contracts/did/IdentityManager.sol";
import "forge-std/Test.sol";

contract IdentityCheckerTest is Test {
    IdentityManager internal identityManager;
    IdentityCheckerHarness internal identityChecker;

    function setUp() external {
        identityManager = new IdentityManager();
        identityChecker = new IdentityCheckerHarness(identityManager);
    }

    function test_OnlyAdminItself(address nxid) external {
        vm.prank(nxid);
        assertTrue(identityChecker.exposed_OnlyAdmin(nxid));
    }

    function test_OnlyAdminIdentityManager(address nxid) external {
        vm.prank(address(identityManager));
        assertTrue(identityChecker.exposed_OnlyAdmin(nxid));
    }

    function test_OnlyAdminController(address nxid, address controller) external {
        vm.assume(nxid != controller);
        vm.prank(nxid);
        identityManager.addOnchainController(nxid, controller, 10000, bytes("0x0"));
        vm.prank(controller);
        assertTrue(identityChecker.exposed_OnlyAdmin(nxid));
    }

    function test_RevertIf_CallByNotAdmin(address notAdmin) external {
        vm.assume(address(this) != notAdmin && address(identityManager) != notAdmin);
        vm.expectRevert("You are not an owner.");
        vm.prank(notAdmin);
        identityChecker.exposed_OnlyAdmin(address(this));
    }
}
