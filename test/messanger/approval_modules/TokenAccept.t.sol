// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {IdentityManager} from "contracts/did/IdentityManager.sol";
import {TokenAccept} from "contracts/messanger/approval_modules/TokenAccept.sol";
import "openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";

contract RejectEveryoneTest is Test {
    event TokenRemoved(address indexed userNxid, address indexed tokenAddress);
    event RequiredTokenAmountSet(address indexed userNxid, address indexed tokenAddress, uint256 requiredAmount);

    TokenAccept internal module;
    IdentityManager internal identityManager;
    ERC20Mock internal token;

    function setUp() public {
        identityManager = new IdentityManager();
        token = new ERC20Mock();
        module = new TokenAccept(identityManager);
    }

    modifier checkRequiredAmount(uint256 amount) {
        assertEq(module.requiredTokenAmounts(address(this), address(token)), 0);
        assertEq(module.getTokens(address(this)).length, 0);

        _;

        assertEq(module.getTokens(address(this)).length, 1);
        assertEq(module.getTokens(address(this))[0], address(token));
        assertEq(module.requiredTokenAmounts(address(this), address(token)), amount);
    }

    modifier tokenAdded(uint256 amount) {
        vm.assume(amount != 0);
        module.setRequiredTokenAmount(address(this), address(token), amount);
        _;
    }

    function test_SetRequiredTokenAmount(uint256 amount) external checkRequiredAmount(amount) {
        vm.assume(amount != 0);

        vm.expectEmit();
        emit RequiredTokenAmountSet(address(this), address(token), amount);
        module.setRequiredTokenAmount(address(this), address(token), amount);
    }

    function test_SetSameRequiredAmount() external {
        uint256 amount = module.requiredTokenAmounts(address(this), address(token));
        vm.expectRevert("Required amount must change.");
        module.setRequiredTokenAmount(address(this), address(token), amount);
    }

    function test_ChangeRequiredAmount(uint256 firstAmount, uint256 secondAmount)
        external
        checkRequiredAmount(secondAmount)
    {
        vm.assume(firstAmount != 0);
        vm.assume(secondAmount != firstAmount);
        module.setRequiredTokenAmount(address(this), address(token), firstAmount);
        assertEq(module.requiredTokenAmounts(address(this), address(token)), firstAmount);

        module.setRequiredTokenAmount(address(this), address(token), secondAmount);
    }

    function test_ChangeRequiredAmountToZero(uint256 firstAmount) external checkRequiredAmount(0) {
        vm.assume(firstAmount != 0);
        module.setRequiredTokenAmount(address(this), address(token), firstAmount);
        assertEq(module.requiredTokenAmounts(address(this), address(token)), firstAmount);

        module.setRequiredTokenAmount(address(this), address(token), 0);
    }

    function test_RevertIf_SetRequiredTokenAmountNotAuthorized(address notAdmin, uint256 amount) external {
        vm.assume(amount != 0);
        vm.assume(notAdmin != address(this) && address(identityManager) != notAdmin);
        vm.expectRevert("You are not an owner.");
        vm.prank(notAdmin);
        module.setRequiredTokenAmount(address(this), address(token), amount);
    }

    function test_RemoveToken(uint256 amount) external tokenAdded(amount) {
        assertEq(module.getTokens(address(this)).length, 1);
        assertEq(module.getTokens(address(this))[0], address(token));

        vm.expectEmit();
        emit TokenRemoved(address(this), address(token));
        module.removeToken(address(this), address(token));

        assertEq(module.getTokens(address(this)).length, 0);
    }

    function test_RevertIf_RemoveNotAddedToken() external {
        vm.expectRevert("Token is not in list.");
        module.removeToken(address(this), address(token));
        assertEq(module.requiredTokenAmounts(address(this), address(token)), 0);
    }

    function test_RevertIf_RemoveTokenNotAuthorized(address notAdmin) external {
        vm.assume(notAdmin != address(this) && address(identityManager) != notAdmin);
        vm.expectRevert("You are not an owner.");
        vm.prank(notAdmin);
        module.removeToken(address(this), address(token));
    }

    function test_IsApprovedIfBalanceIsSameAsAmount(address nxidToCheck, uint256 amount) external tokenAdded(amount) {
        deal(address(token), nxidToCheck, amount);
        assertTrue(module.isApproved(address(this), nxidToCheck));
    }

    function test_IsApprovedIfBalanceIsHigher(address nxidToCheck, uint256 amount) external tokenAdded(amount) {
        vm.assume(amount != type(uint256).max);
        deal(address(token), nxidToCheck, amount + 1);
        assertTrue(module.isApproved(address(this), nxidToCheck));
    }

    function test_IsApprovedIfNotEnoughTokens(address nxidToCheck, uint256 amount) external tokenAdded(amount) {
        deal(address(token), nxidToCheck, amount - 1);
        assertFalse(module.isApproved(address(this), nxidToCheck));
    }
}
