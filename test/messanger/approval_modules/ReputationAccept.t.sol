// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IdentityManager} from "contracts/did/IdentityManager.sol";
import {ModuleStorage} from "contracts/messanger/ModuleStorage.sol";
import {ReputationAccept} from "contracts/messanger/approval_modules/ReputationAccept.sol";
import {ClubReputationTestBase} from "../messanger_units/ClubRegistry.t.sol";
import "forge-std/Test.sol";

contract ReputationAcceptTest is ClubReputationTestBase {
    event RequiredReputationSet(address indexed userNxid, address indexed clubNxid, uint256 requiredReputation);
    event ClubRemoved(address indexed userNxid, address indexed _clubNxid);

    ReputationAccept internal module;

    function setUp() public override {
        super.setUp();
        module = new ReputationAccept(clubRegistry, identityManager);
    }

    modifier checkRequiredAmount(address userNxid, uint256 amount) {
        assertEq(module.requiredReputation(userNxid, address(this)), 0);
        assertEq(module.getClubs(userNxid).length, 0);

        _;

        assertEq(module.getClubs(userNxid).length, 1);
        assertEq(module.getClubs(userNxid)[0], address(this));
        assertEq(module.requiredReputation(userNxid, address(this)), amount);
    }

    modifier reputationSet(address userNxid, uint256 amount) {
        vm.assume(amount != 0);
        vm.prank(userNxid);
        module.setRequiredReputation(userNxid, address(this), amount);
        _;
    }

    function test_setRequiredReputation(address userNxid, uint256 amount)
        external
        checkRequiredAmount(userNxid, amount)
    {
        vm.assume(amount != 0);

        vm.expectEmit();
        emit RequiredReputationSet(userNxid, address(this), amount);
        vm.prank(userNxid);
        module.setRequiredReputation(userNxid, address(this), amount);
    }

    function test_SetSameRequiredAmount(address userNxid) external {
        uint256 amount = module.requiredReputation(userNxid, address(this));
        vm.expectRevert("Required reputation must change.");
        vm.prank(userNxid);
        module.setRequiredReputation(userNxid, address(this), amount);
    }

    function test_ChangeRequiredAmount(address userNxid, uint256 firstAmount, uint256 secondAmount)
        external
        checkRequiredAmount(userNxid, secondAmount)
    {
        vm.assume(firstAmount != 0);
        vm.assume(secondAmount != firstAmount);
        vm.startPrank(userNxid);
        module.setRequiredReputation(userNxid, address(this), firstAmount);
        assertEq(module.requiredReputation(userNxid, address(this)), firstAmount);

        module.setRequiredReputation(userNxid, address(this), secondAmount);
        vm.stopPrank();
    }

    function test_RevertIf_SetRequiredAmountNotAuthorized(address userNxid, address notAdmin, uint256 amount)
        external
    {
        vm.assume(amount != 0);
        vm.assume(notAdmin != userNxid && address(identityManager) != notAdmin);
        vm.expectRevert("You are not an owner.");
        vm.prank(notAdmin);
        module.setRequiredReputation(userNxid, address(this), amount);
    }

    function test_RemoveClub(address userNxid, uint256 amount) external reputationSet(userNxid, amount) {
        assertEq(module.getClubs(userNxid).length, 1);
        assertEq(module.getClubs(userNxid)[0], address(this));
        assertEq(module.requiredReputation(userNxid, address(this)), amount);

        vm.prank(userNxid);
        module.removeClub(userNxid, address(this));

        assertEq(module.getClubs(userNxid).length, 0);
        assertEq(module.requiredReputation(userNxid, address(this)), 0);
    }

    function test_RemoveClubIfNotAdded(address userNxid) external {
        vm.expectRevert("Club is not in list.");
        vm.prank(userNxid);
        module.removeClub(userNxid, address(this));
    }

    function test_RemoveClubByNotOwner(address userNxid, address notAdmin) external {
        vm.assume(notAdmin != userNxid && address(identityManager) != notAdmin);
        vm.expectRevert("You are not an owner.");
        vm.prank(notAdmin);
        module.removeClub(userNxid, address(this));
    }

    function test_IsApprovedIfEnoughReputation(address targetNxid, address nxidToCheck, address reputationSender)
        external
        membershipAndReputationAllowed
        clubMember(nxidToCheck)
        clubMember(reputationSender)
        reputationAdded(nxidToCheck, reputationSender)
        reputationSet(targetNxid, 1)
    {
        assertTrue(module.isApproved(targetNxid, nxidToCheck));
    }

    function test_IsApprovedIfNotEnoughReputation(address targetNxid, address nxidToCheck, address reputationSender)
        external
        membershipAndReputationAllowed
        clubMember(nxidToCheck)
        clubMember(reputationSender)
        reputationAdded(nxidToCheck, reputationSender)
        reputationSet(targetNxid, 10)
    {
        assertFalse(module.isApproved(targetNxid, nxidToCheck));
    }
}
