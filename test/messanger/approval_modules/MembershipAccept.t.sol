// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IdentityManager} from "contracts/did/IdentityManager.sol";
import {ModuleStorage} from "contracts/messanger/ModuleStorage.sol";
import {MembershipAccept} from "contracts/messanger/approval_modules/MembershipAccept.sol";
import {ClubReputationTestBase} from "../messanger_units/ClubRegistry.t.sol";
import "forge-std/Test.sol";

contract MembershipAcceptTest is ClubReputationTestBase {
    event ClubWhitelisted(address indexed userNxid, address _clubNxid);
    event ClubRemoved(address indexed userNxid, address _clubNxid);

    MembershipAccept internal module;

    function setUp() public override {
        super.setUp();
        module = new MembershipAccept(clubRegistry, identityManager);
    }

    function test_AddClub(address clubNxid) external {
        vm.expectEmit();
        emit ClubWhitelisted(address(this), clubNxid);
        assertEq(module.getClubs(address(this)).length, 0);
        module.addClub(address(this), clubNxid);
        assertEq(module.getClubs(address(this)).length, 1);
        assertEq(module.getClubs(address(this))[0], clubNxid);
    }

    function test_RevertIf_AddClubTwice(address clubNxid) external {
        module.addClub(address(this), clubNxid);
        vm.expectRevert("Club already added.");
        module.addClub(address(this), clubNxid);
    }

    function test_RevertIf_AddClubNotAuthorized(address clubNxid, address notAdmin) external {
        vm.assume(notAdmin != address(this) && notAdmin != address(identityManager));
        vm.expectRevert("You are not an owner.");
        vm.prank(notAdmin);
        module.addClub(address(this), clubNxid);
    }

    modifier clubAdded(address userNxid, address clubNxid) {
        vm.prank(userNxid);
        module.addClub(userNxid, clubNxid);
        _;
    }

    function test_RemoveClub(address clubNxid) external clubAdded(address(this), clubNxid) {
        assertEq(module.getClubs(address(this)).length, 1);

        vm.expectEmit();
        emit ClubRemoved(address(this), clubNxid);
        module.removeClub(address(this), clubNxid);

        assertEq(module.getClubs(address(this)).length, 0);
    }

    function test_RevertIf_RemoveClubIfNotExist(address clubNxid) external {
        vm.expectRevert("Club is not in list.");
        module.removeClub(address(this), clubNxid);
    }

    function test_RevertIf_RemoveClubNotAuthorized(address clubNxid, address notAdmin) external {
        vm.assume(notAdmin != address(this) && notAdmin != address(identityManager));
        vm.expectRevert("You are not an owner.");
        vm.prank(notAdmin);
        module.removeClub(address(this), clubNxid);
    }

    function test_IsApproved(address nxidToCheck, address targetNxid)
        external
        clubMembershipAllowed
        clubMember(nxidToCheck)
        clubAdded(targetNxid, address(this))
    {
        assertTrue(module.isApproved(targetNxid, nxidToCheck));
    }

    function test_IsApprovedIfNotClubMember(address nxidToCheck, address targetNxid)
        external
        clubMembershipAllowed
        clubAdded(targetNxid, address(this))
    {
        assertFalse(module.isApproved(targetNxid, nxidToCheck));
    }
}
