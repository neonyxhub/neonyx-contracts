// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "contracts/messanger/ModuleStorage.sol";
import {IdentityManager} from "contracts/did/IdentityManager.sol";
import {RejectEveryone} from "contracts/messanger/approval_modules/RejectEveryone.sol";
import {AcceptEveryone} from "contracts/messanger/approval_modules/AcceptEveryone.sol";

contract ModuleStorageTestBase is Test {
    event WhitelistModuleAdded(address indexed moduleAddress);
    event BlacklistModuleAdded(address indexed moduleAddress);
    event WhitelistModuleRemoved(address indexed moduleAddress);
    event BlacklistModuleRemoved(address indexed moduleAddress);

    ModuleStorage internal moduleStorage;
    IdentityManager internal identityManager;
    RejectEveryone internal rejectEveryoneModule;
    AcceptEveryone internal acceptEveryoneModule;

    function setUp() external virtual {
        identityManager = new IdentityManager();
        moduleStorage = new ModuleStorage(identityManager);
        rejectEveryoneModule = new RejectEveryone(identityManager);
        acceptEveryoneModule = new AcceptEveryone(identityManager);
    }

    modifier whitelistEveryoneModuleAdded() {
        moduleStorage.addWhitelistModule(address(this), address(acceptEveryoneModule));
        _;
    }

    modifier blacklistEveryoneModuleAdded() {
        moduleStorage.addBlacklistModule(address(this), address(acceptEveryoneModule));
        _;
    }
}

contract ModuleStorageAddWhitelistModuleTest is ModuleStorageTestBase {
    function test_AddWhitelistModule() external {
        assertEq(moduleStorage.getWhitelistModules(address(this)).length, 0);
        vm.expectEmit();
        emit WhitelistModuleAdded(address(acceptEveryoneModule));
        moduleStorage.addWhitelistModule(address(this), address(acceptEveryoneModule));
        assertEq(moduleStorage.getWhitelistModules(address(this)).length, 1);
        assertEq(moduleStorage.getWhitelistModules(address(this))[0], address(acceptEveryoneModule));
    }

    function test_RevertId_TwiceAddWhitelistModule() external {
        assertEq(moduleStorage.getWhitelistModules(address(this)).length, 0);
        moduleStorage.addWhitelistModule(address(this), address(acceptEveryoneModule));
        vm.expectRevert("This module is already in whitelist.");
        moduleStorage.addWhitelistModule(address(this), address(acceptEveryoneModule));
    }

    function test_RevertIf_AddWhitelistModuleByNotAdmin(address notAdmin) external {
        vm.assume(address(this) != notAdmin && notAdmin != address(identityManager));
        vm.expectRevert("You are not an owner.");
        vm.prank(notAdmin);
        moduleStorage.addWhitelistModule(address(this), address(acceptEveryoneModule));
    }

    function test_RevertIf_AddNotModule() external {
        vm.expectRevert("Contract is not approval module.");
        moduleStorage.addWhitelistModule(address(this), address(0));
    }
}

contract ModuleStorageAddBlacklistModuleTest is ModuleStorageTestBase {
    function test_AddBlacklistModule() external {
        assertEq(moduleStorage.getBlacklistModules(address(this)).length, 0);
        vm.expectEmit();
        emit BlacklistModuleAdded(address(acceptEveryoneModule));
        moduleStorage.addBlacklistModule(address(this), address(acceptEveryoneModule));
        assertEq(moduleStorage.getBlacklistModules(address(this)).length, 1);
        assertEq(moduleStorage.getBlacklistModules(address(this))[0], address(acceptEveryoneModule));
    }

    function test_RevertId_TwiceAddBlacklistModule() external {
        assertEq(moduleStorage.getBlacklistModules(address(this)).length, 0);
        moduleStorage.addBlacklistModule(address(this), address(acceptEveryoneModule));
        vm.expectRevert("This module is already in blacklist.");
        moduleStorage.addBlacklistModule(address(this), address(acceptEveryoneModule));
    }

    function test_AddBlacklistModuleByNotAdmin(address notAdmin) external {
        vm.assume(notAdmin != address(this) && notAdmin != address(identityManager));
        vm.expectRevert("You are not an owner.");
        vm.prank(notAdmin);
        moduleStorage.addBlacklistModule(address(this), address(acceptEveryoneModule));
    }

    function test_RevertIf_AddNotModule() external {
        vm.expectRevert("Contract is not approval module.");
        moduleStorage.addBlacklistModule(address(this), address(0));
    }
}

contract ModuleStorageRemoveWhitelistModuleTest is ModuleStorageTestBase {
    function test_RemoveWhitelistModule() external whitelistEveryoneModuleAdded {
        assertEq(moduleStorage.getWhitelistModules(address(this)).length, 1);
        vm.expectEmit();
        emit WhitelistModuleRemoved(address(acceptEveryoneModule));
        moduleStorage.removeWhitelistModule(address(this), address(acceptEveryoneModule));
        assertEq(moduleStorage.getWhitelistModules(address(this)).length, 0);
    }

    function test_RevertIf_RemoveWhitelistModuleIfNotExist() external {
        vm.expectRevert("This module is not in your whitelist.");
        moduleStorage.removeWhitelistModule(address(this), address(acceptEveryoneModule));
    }

    function test_RevertIf_RemoveWhitelistModuleByNotAdmin(address notAdmin) external {
        vm.assume(address(this) != notAdmin && notAdmin != address(identityManager));
        vm.expectRevert("You are not an owner.");
        vm.prank(notAdmin);
        moduleStorage.removeWhitelistModule(address(this), address(acceptEveryoneModule));
    }
}

contract ModuleStorageRemoveBlacklistModuleTest is ModuleStorageTestBase {
    function test_RemoveBlacklistModule() external blacklistEveryoneModuleAdded {
        assertEq(moduleStorage.getBlacklistModules(address(this)).length, 1);
        vm.expectEmit();
        emit BlacklistModuleRemoved(address(acceptEveryoneModule));
        moduleStorage.removeBlacklistModule(address(this), address(acceptEveryoneModule));
        assertEq(moduleStorage.getBlacklistModules(address(this)).length, 0);
    }

    function test_RevertIf_RemoveBlacklistModuleIfNotExist() external {
        vm.expectRevert("This module is not in your blacklist.");
        moduleStorage.removeBlacklistModule(address(this), address(acceptEveryoneModule));
    }

    function test_RevertIf_RemoveBlacklistModuleByNotAdmin(address notAdmin) external {
        vm.assume(address(this) != notAdmin && notAdmin != address(identityManager));
        vm.expectRevert("You are not an owner.");
        vm.prank(notAdmin);
        moduleStorage.removeBlacklistModule(address(this), address(acceptEveryoneModule));
    }
}

contract ModuleStorageRequiredApprovalsTest is ModuleStorageTestBase {
    function test_SetRequiredApprovals() external {
        assertEq(moduleStorage.getRequiredApprovals(address(this)), 0);
        moduleStorage.setRequiredApprovals(address(this), 1);
        moduleStorage.addWhitelistModule(address(this), address(acceptEveryoneModule));
        assertEq(moduleStorage.getRequiredApprovals(address(this)), 1);
    }

    function test_GetRequiredApprovalsIfNotEnoughModules() external {
        assertEq(moduleStorage.getRequiredApprovals(address(this)), 0);
        moduleStorage.setRequiredApprovals(address(this), 5);
        assertEq(moduleStorage.getRequiredApprovals(address(this)), 0);
        moduleStorage.addWhitelistModule(address(this), address(acceptEveryoneModule));
        assertEq(moduleStorage.getRequiredApprovals(address(this)), 1);
    }

    function test_GetRequiredApprovalsIfOnlyModuleAdded() external whitelistEveryoneModuleAdded {
        assertEq(moduleStorage.getRequiredApprovals(address(this)), 1);
    }

    function test_GetRequiredApprovalsWithNoTransactions() external {
        assertEq(moduleStorage.getRequiredApprovals(address(this)), 0);
    }

    function test_GetRequiredApprovalsIfLowerThanModuleAmount() external {
        moduleStorage.addWhitelistModule(address(this), address(acceptEveryoneModule));
        moduleStorage.addWhitelistModule(address(this), address(rejectEveryoneModule));
        moduleStorage.setRequiredApprovals(address(this), 1);
        assertEq(moduleStorage.getRequiredApprovals(address(this)), 1);
    }
}

contract ModuleStorageIsWhitelistedTest is ModuleStorageTestBase {
    function test_IsWhitelistedIfApproved(address nxidToCheck) external whitelistEveryoneModuleAdded {
        assertTrue(moduleStorage.isWhitelisted(address(this), nxidToCheck));
    }

    function test_IsWhitelistedIfNotApproved(address nxidToCheck) external {
        moduleStorage.addWhitelistModule(address(this), address(rejectEveryoneModule));
        assertFalse(moduleStorage.isWhitelisted(address(this), nxidToCheck));
    }

    function test_IsWhitelistedIfNoModulesAdded(address nxidToCheck) external {
        assertFalse(moduleStorage.isWhitelisted(address(this), nxidToCheck));
    }

    function test_IsWhitelistedIfNotEnoughApprovals(address nxidToCheck) external whitelistEveryoneModuleAdded {
        moduleStorage.addWhitelistModule(address(this), address(rejectEveryoneModule));
        moduleStorage.setRequiredApprovals(address(this), 2);
        assertFalse(moduleStorage.isWhitelisted(address(this), nxidToCheck));
    }

    function test_IsWhitelistedIfModulesAmountHigherThanRequiredApprovals(address nxidToCheck)
        external
        whitelistEveryoneModuleAdded
    {
        moduleStorage.addWhitelistModule(address(this), address(rejectEveryoneModule));
        moduleStorage.setRequiredApprovals(address(this), 1);
        assertTrue(moduleStorage.isWhitelisted(address(this), nxidToCheck));
    }
}

contract ModuleStorageIsBlacklistedTest is ModuleStorageTestBase {
    function test_IsBlacklistedIfApproved(address nxidToCheck) external {
        moduleStorage.addBlacklistModule(address(this), address(acceptEveryoneModule));
        assertTrue(moduleStorage.isBlacklisted(address(this), nxidToCheck));
    }

    function test_IsBlacklistedIfNotApproved(address nxidToCheck) external {
        moduleStorage.addBlacklistModule(address(this), address(rejectEveryoneModule));
        assertFalse(moduleStorage.isBlacklisted(address(this), nxidToCheck));
    }

    function test_IsBlacklistedIfApprovedByOneModule(address nxidToCheck) external {
        moduleStorage.addBlacklistModule(address(this), address(rejectEveryoneModule));
        moduleStorage.addBlacklistModule(address(this), address(acceptEveryoneModule));
        assertTrue(moduleStorage.isBlacklisted(address(this), nxidToCheck));
    }

    function test_IsBlacklistedIfNoModules(address nxidToCheck) external {
        assertFalse(moduleStorage.isBlacklisted(address(this), nxidToCheck));
    }
}

contract ModuleStorageIsApprovedTest is ModuleStorageTestBase {
    function test_IsApprovedIfApproved(address nxidToCheck) external whitelistEveryoneModuleAdded {
        moduleStorage.checkApproval(address(this), nxidToCheck);
    }

    function test_IsApprovedIfBlacklisted(address nxidToCheck) external whitelistEveryoneModuleAdded {
        moduleStorage.addBlacklistModule(address(this), address(acceptEveryoneModule));
        vm.expectRevert("You are blacklisted.");
        moduleStorage.checkApproval(address(this), nxidToCheck);
    }

    function test_IsApprovedIfNotWhitelisted(address nxidToCheck) external {
        vm.expectRevert("You are not whitelisted.");
        moduleStorage.checkApproval(address(this), nxidToCheck);
    }
}
