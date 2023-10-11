// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IdentityManager} from "contracts/did/IdentityManager.sol";
import {ModuleStorage} from "contracts/messanger/ModuleStorage.sol";
import {RendezvousPoint} from "contracts/messanger/RendezvousPoint.sol";
import {ManualAccept} from "contracts/messanger/approval_modules/ManualAccept.sol";
import "forge-std/Test.sol";

contract ManualAcceptModuleTest is Test {
    event AddressAdded(address indexed userNxid, address indexed addedNxid);
    event AddressRemoved(address indexed userNxid, address indexed removedNxid);

    ManualAccept internal module;
    IdentityManager internal identityManager;

    function setUp() public {
        identityManager = new IdentityManager();
        module = new ManualAccept(identityManager);
    }

    function test_AddAddress(address nxidToAdd) external {
        assertEq(module.getAddresses(address(this)).length, 0);
        vm.expectEmit();
        emit AddressAdded(address(this), nxidToAdd);
        module.addAddress(address(this), nxidToAdd);
        assertEq(module.getAddresses(address(this)).length, 1);
        assertEq(module.getAddresses(address(this))[0], nxidToAdd);
    }

    function test_RevertIf_TwiceAddAddress(address nxidToAdd) external {
        module.addAddress(address(this), nxidToAdd);

        vm.expectRevert("Address is already in list.");
        module.addAddress(address(this), nxidToAdd);
    }

    function test_RevertIf_AddAddressByNotAdmin(address nxidToAdd, address sender) external {
        vm.assume(sender != address(this) && sender != address(identityManager));
        vm.expectRevert("You are not an owner.");
        vm.prank(sender);
        module.addAddress(address(this), nxidToAdd);
    }

    function test_RemoveAddress(address nxidToRemove) external {
        module.addAddress(address(this), nxidToRemove);
        assertEq(module.getAddresses(address(this)).length, 1);
        assertEq(module.getAddresses(address(this))[0], nxidToRemove);
        vm.expectEmit();
        emit AddressRemoved(address(this), nxidToRemove);
        module.removeAddress(address(this), nxidToRemove);
        assertEq(module.getAddresses(address(this)).length, 0);
    }

    function test_RevertIf_RemoveAlreadyRemoved(address nxidToAdd) external {
        vm.expectRevert("Address is not in list.");
        module.removeAddress(address(this), nxidToAdd);
    }

    function test_RevertIf_RemoveAddressByNotAdmin(address nxidToAdd, address sender) external {
        vm.assume(sender != address(this) && sender != address(identityManager));
        vm.expectRevert("You are not an owner.");
        vm.prank(sender);
        module.removeAddress(address(this), nxidToAdd);
    }

    function test_IsApprovedIfApproved(address nxidToCheck) external {
        module.addAddress(address(this), nxidToCheck);
        assertTrue(module.isApproved(address(this), nxidToCheck));
    }

    function test_IsApprovedIfNotApproved(address nxidToCheck) external {
        assertFalse(module.isApproved(address(this), nxidToCheck));
    }
}
