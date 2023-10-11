// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IdentityManager} from "contracts/did/IdentityManager.sol";
import {ModuleStorage} from "contracts/messanger/ModuleStorage.sol";
import {RendezvousPoint} from "contracts/messanger/RendezvousPoint.sol";
import {PaymentAccept} from "contracts/messanger/approval_modules/PaymentAccept.sol";
import "forge-std/Test.sol";
import "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract PaymentAcceptModuleTest is Test {
    event RequiredAmountSet(address indexed userNxid, address indexed tokenAddress, uint256 value);
    event AddressApproved(address indexed userNxid, address indexed approvedAddress);

    PaymentAccept internal module;
    ERC20Mock internal token;
    IdentityManager internal identityManager;

    function setUp() public {
        identityManager = new IdentityManager();
        module = new PaymentAccept(identityManager);
        token = new ERC20Mock();
    }

    function test_SetRequiredAmount(uint256 amount) external {
        assertEq(module.requiredAmount(address(this), address(token)), 0);

        vm.expectEmit();
        emit RequiredAmountSet(address(this), address(token), amount);
        module.setRequiredAmount(address(this), address(token), amount);
        assertEq(module.requiredAmount(address(this), address(token)), amount);
    }

    function test_RevertIf_SetRequiredAmountByNotAdmin(address notAdmin, uint256 amount) external {
        vm.assume(notAdmin != address(this) && address(identityManager) != notAdmin);
        vm.expectRevert("You are not an owner.");
        vm.prank(notAdmin);
        module.setRequiredAmount(address(this), address(token), amount);
    }

    function test_SendNativePayment(uint256 amount) external {
        address receiver = address(0x123);
        address sender = address(0x12345);
        vm.assume(amount != 0);
        deal(sender, amount);
        assertEq(sender.balance, amount);
        vm.prank(receiver);
        module.setRequiredAmount(receiver, address(0), amount);
        vm.expectEmit();
        emit AddressApproved(receiver, sender);
        vm.prank(sender);
        module.sendPayment{value: amount}(sender, receiver, address(0), amount);
        assertTrue(module.approved(receiver, sender));
        assertEq(sender.balance, 0);
        assertEq(receiver.balance, amount);
    }

    function test_SendTokenIfNotApproved(address sender, address receiver) external {
        vm.expectRevert("This token is not approved by receiver.");
        vm.prank(sender);
        module.sendPayment(sender, receiver, address(0), 0);
    }

    function test_SendTokenIfNotEnough(address sender, address receiver, uint256 amount) external {
        vm.assume(amount != 0);
        vm.prank(receiver);
        module.setRequiredAmount(receiver, address(token), amount);
        vm.expectRevert("Insufficient amount sent. Please send the correct amount.");
        vm.prank(sender);
        module.sendPayment(sender, receiver, address(token), amount - 1);
    }

    function test_SendToken(address sender, address receiver, uint256 amount) external {
        vm.assume(amount != 0);
        vm.assume(sender != receiver);
        assumeNotZeroAddress(sender);
        assumeNotZeroAddress(receiver);

        token.mint(sender, amount);
        assertEq(token.balanceOf(sender), amount);
        vm.prank(receiver);
        module.setRequiredAmount(receiver, address(token), amount);
        vm.prank(sender);
        token.approve(address(module), amount);
        vm.prank(sender);
        vm.expectEmit();
        emit AddressApproved(receiver, sender);
        module.sendPayment{value: 0}(sender, receiver, address(token), amount);
        assertTrue(module.approved(receiver, sender));
        assertEq(token.balanceOf(sender), 0);
        assertEq(token.balanceOf(receiver), amount);
    }

    function test_sendPaymentIfAlreadyApproved(address sender, address receiver, uint256 amount) external {
        assumeNotZeroAddress(sender);
        assumeNotZeroAddress(receiver);
        vm.assume(amount != 0);
        token.mint(sender, amount);
        vm.prank(receiver);
        module.setRequiredAmount(receiver, address(token), amount);
        vm.prank(sender);
        token.approve(address(module), amount);
        vm.prank(sender);
        module.sendPayment(sender, receiver, address(token), amount);
        assertTrue(module.approved(receiver, sender));
        vm.expectRevert("Already approved.");
        vm.prank(sender);
        module.sendPayment(sender, receiver, address(token), amount);
    }

    function test_IsApprovedIfApproved(address sender, address receiver, uint256 amount) external {
        assumeNotZeroAddress(sender);
        assumeNotZeroAddress(receiver);
        vm.assume(amount != 0);
        token.mint(sender, amount);
        vm.prank(receiver);
        module.setRequiredAmount(receiver, address(token), amount);
        vm.prank(sender);
        token.approve(address(module), amount);
        vm.prank(sender);
        module.sendPayment(sender, receiver, address(token), amount);
        assertTrue(module.isApproved(receiver, sender));
    }

    function test_IsApprovedIfNotApproved(address sender, address receiver) external {
        assertFalse(module.isApproved(receiver, sender));
    }
}
