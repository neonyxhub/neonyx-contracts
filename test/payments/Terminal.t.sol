// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "contracts/payments/Terminal.sol";
import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract TerminalBase is Test {
    Terminal internal terminal;
    ERC20Mock internal token;
    address internal tokenAddress;

    function setUp() public virtual {
        token = new ERC20Mock();
        tokenAddress = address(token);
        terminal = new Terminal();
    }

    function _getAccessControlRevertMessage(address account, bytes32 role)
        internal
        pure
        returns (bytes memory revertMessage)
    {
        revertMessage = abi.encodePacked(
            "AccessControl: account ",
            Strings.toHexString(account),
            " is missing role ",
            Strings.toHexString(uint256(role), 32)
        );
    }
}

contract TerminalTokensTest is TerminalBase {
    function test_AddWhitelistToken(address token) external {
        assertEq(terminal.getWhitelistedTokens().length, 0);
        terminal.addWhitelistedToken(token);
        assertEq(terminal.getWhitelistedTokens().length, 1);
        assertEq(terminal.getWhitelistedTokens()[0], token);
    }

    function test_RevertIf_AddTokenTwice(address token) external {
        terminal.addWhitelistedToken(token);
        assertEq(terminal.getWhitelistedTokens()[0], token);

        vm.expectRevert("Token is already whitelisted.");
        terminal.addWhitelistedToken(token);
    }

    function test_RemoveWhitelistToken(address token) external {
        terminal.addWhitelistedToken(token);
        assertEq(terminal.getWhitelistedTokens().length, 1);
        assertEq(terminal.getWhitelistedTokens()[0], token);

        terminal.removeWhitelistedToken(token);
        assertEq(terminal.getWhitelistedTokens().length, 0);
    }

    function test_RevertIf_RemoveNotWhitelistedToken(address token) external {
        vm.expectRevert("Token is not whitelisted.");
        terminal.removeWhitelistedToken(token);
    }

    function test_RevertIf_AddTokenByNotAdmin(address notOwner, address token) external {
        vm.assume(notOwner != address(this));
        bytes memory revertMessage = _getAccessControlRevertMessage(notOwner, terminal.DEFAULT_ADMIN_ROLE());
        vm.expectRevert(revertMessage);
        vm.prank(notOwner);
        terminal.addWhitelistedToken(token);
    }

    function test_RevertIf_RemoveTokenByNotAdmin(address notOwner, address token) external {
        vm.assume(notOwner != address(this));
        terminal.addWhitelistedToken(token);
        bytes memory revertMessage = _getAccessControlRevertMessage(notOwner, terminal.DEFAULT_ADMIN_ROLE());
        vm.expectRevert(revertMessage);
        vm.prank(notOwner);
        terminal.removeWhitelistedToken(token);
    }
}

abstract contract PreparationUtils is Test {
    function _prepareTokenTransfer(address sender, address receiver, ERC20Mock token, uint256 amount) internal {
        assumeNotZeroAddress(sender);
        assumeNotZeroAddress(receiver);
        vm.assume(amount != 0);
        vm.assume(sender != receiver);

        token.mint(sender, amount);
        vm.prank(sender);
        token.approve(receiver, amount);
    }

    modifier tokenTransferPrepared(
        address sender,
        address receiver,
        ERC20Mock token,
        uint256 amount,
        uint256 expectedSenderAmount,
        uint256 expectedReceiverAmount
    ) {
        _prepareTokenTransfer(sender, receiver, token, amount);

        assertEq(token.balanceOf(receiver), 0);
        assertEq(token.balanceOf(sender), amount);

        _;

        assertEq(token.balanceOf(receiver), expectedReceiverAmount);
        assertEq(token.balanceOf(sender), expectedSenderAmount);
    }

    modifier nativeTokenTransferPrepared(address sender, address receiver, uint256 amount) {
        vm.assume(amount != 0);
        vm.assume(sender != receiver);

        deal(sender, amount);

        assertEq(receiver.balance, 0);
        assertEq(sender.balance, amount);
        _;

        assertEq(receiver.balance, amount);
        assertEq(sender.balance, 0);
    }
}

contract TerminalOrderPaymentTest is PreparationUtils, TerminalBase {
    event PaymentReceived(address indexed sender, address indexed token, uint256 amount);

    function test_OrderPaymentErc20Token(address payer, uint256 amount)
        external
        tokenTransferPrepared(payer, address(terminal), token, amount, 0, amount)
    {
        terminal.addWhitelistedToken(tokenAddress);

        vm.prank(payer);
        vm.expectEmit(true, true, true, true);
        emit PaymentReceived(payer, tokenAddress, amount);

        terminal.orderPayment(tokenAddress, amount);
    }

    function test_OrderPaymentNativeToken(address payer, uint256 amount)
        external
        nativeTokenTransferPrepared(payer, address(terminal), amount)
    {
        terminal.addWhitelistedToken(address(0));

        vm.prank(payer);
        vm.expectEmit(true, true, true, true);
        emit PaymentReceived(payer, address(0), amount);

        terminal.orderPayment{value: amount}(address(0), 0);
    }

    function test_RevertIf_EmptyPayment(address payer) external {
        vm.expectRevert("Amount must be greater than zero.");
        vm.prank(payer);
        terminal.orderPayment{value: 0}(address(0), 0);
    }

    function test_OrderPaymentInBothTokens(address payer, uint256 nativeAmount, uint256 tokenAmount)
        external
        nativeTokenTransferPrepared(payer, address(terminal), nativeAmount)
        tokenTransferPrepared(payer, address(terminal), token, tokenAmount, tokenAmount, 0)
    {
        terminal.addWhitelistedToken(tokenAddress);
        terminal.addWhitelistedToken(address(0));

        vm.prank(payer);
        vm.expectEmit(true, true, true, true);
        emit PaymentReceived(payer, address(0), nativeAmount);

        terminal.orderPayment{value: nativeAmount}(tokenAddress, tokenAmount);
    }

    function test_RevertIf_orderPaymentWithPausedContract(address payer) external {
        terminal.grantRole(terminal.PAUSE_ROLE(), address(this));
        terminal.pause();
        vm.expectRevert("Pausable: paused");
        vm.prank(payer);
        terminal.orderPayment(address(0), 0);
    }

    function test_RevertIf_OrderPaymentWithNotWhitelistedNativeToken(address payer, uint256 amount) external {
        deal(payer, amount);
        vm.assume(amount > 0);
        vm.expectRevert("Token is not whitelisted.");
        vm.prank(payer);
        terminal.orderPayment{value: amount}(address(0), 0);
    }

    function test_RevertIf_OrderPaymentWithNotWhitelistedToken(address payer, uint256 amount) external {
        vm.assume(amount > 0);
        vm.expectRevert("Token is not whitelisted.");
        vm.prank(payer);
        terminal.orderPayment(tokenAddress, amount);
    }
}

contract SubscriptionBase is PreparationUtils, TerminalBase {
    function _compareSubscriptions(Subscription memory subscription, Subscription memory expectedSubscription)
        internal
    {
        assertEq(subscription.payer, expectedSubscription.payer);
        assertEq(subscription.renewalFrequency, expectedSubscription.renewalFrequency);
        assertEq(subscription.amount, expectedSubscription.amount);
        assertEq(subscription.token, expectedSubscription.token);
        assertEq(subscription.lastPaymentTimestamp, expectedSubscription.lastPaymentTimestamp);
    }

    modifier subscribed(address payer, uint256 amount, uint32 renewalFrequency, uint256 collectAmount) {
        vm.assume(type(uint256).max / collectAmount > amount);
        _prepareTokenTransfer(payer, address(terminal), token, amount * collectAmount);
        vm.warp(uint256(renewalFrequency) + 1000);
        terminal.addWhitelistedToken(tokenAddress);
        vm.prank(payer);
        terminal.subscribe(tokenAddress, amount, renewalFrequency);
        _;
    }
}

contract TerminalSubscriptionTest is SubscriptionBase {
    event SubscriptionCreated(address indexed payer, uint256 subscriptionId);
    event SubscriptionPaid(address indexed payer, uint256 subscriptionId);

    function test_Subscribe(address payer, uint256 amount, uint32 renewalFrequency)
        external
        tokenTransferPrepared(payer, address(terminal), token, amount, 0, amount)
    {
        vm.warp(uint256(renewalFrequency) + 1000);
        terminal.addWhitelistedToken(tokenAddress);
        assertEq(terminal.subscriptionAmount(), 0);
        vm.expectEmit();
        emit SubscriptionPaid(payer, 0);
        vm.expectEmit();
        emit SubscriptionCreated(payer, 0);

        vm.prank(payer);
        terminal.subscribe(tokenAddress, amount, renewalFrequency);

        assertEq(terminal.getUserSubscriptions(payer).length, 1);
        assertEq(terminal.getUserSubscriptions(payer)[0], 0);
        assertEq(terminal.subscriptionAmount(), 1);
        Subscription memory subscription = terminal.getSubscription(0);
        _compareSubscriptions(
            subscription, Subscription(renewalFrequency, uint64(block.timestamp), payer, amount, tokenAddress, false)
        );
    }

    function test_RevertIf_SubscriptionAmountIsZero(address payer, uint32 renewalFrequency) external {
        terminal.addWhitelistedToken(tokenAddress);
        vm.expectRevert("Amount should be positive.");
        vm.prank(payer);
        terminal.subscribe(tokenAddress, 0, renewalFrequency);
    }

    function test_RevertIf_SubscribeWhenTerminalPaused(address payer, uint256 amount, uint32 renewalFrequency)
        external
    {
        terminal.grantRole(terminal.PAUSE_ROLE(), address(this));
        terminal.pause();
        vm.expectRevert("Pausable: paused");
        vm.prank(payer);
        terminal.subscribe(tokenAddress, amount, renewalFrequency);
    }

    function test_RevertIf_TokenIsNotWhitelisted(address payer, uint256 amount, uint32 renewalFrequency) external {
        vm.expectRevert("Token is not whitelisted.");
        vm.prank(payer);
        terminal.subscribe(tokenAddress, amount, renewalFrequency);
    }
}

contract TerminalRevokeSubscriptionTest is SubscriptionBase {
    function test_RevokeSubscription(address payer, uint256 amount, uint32 renewalFrequency)
        external
        subscribed(payer, amount, renewalFrequency, 1)
    {
        uint256 subscriptionId = 0;

        Subscription memory expectedSubscription =
            Subscription(renewalFrequency, uint64(block.timestamp), payer, amount, tokenAddress, false);
        Subscription memory subscription = terminal.getSubscription(subscriptionId);
        _compareSubscriptions(subscription, expectedSubscription);

        vm.prank(payer);
        terminal.revokeSubscription(subscriptionId);

        expectedSubscription.revoked = true;
        subscription = terminal.getSubscription(subscriptionId);
        _compareSubscriptions(subscription, expectedSubscription);
        assertEq(terminal.getUserSubscriptions(payer).length, 0);
    }

    function test_RevertIf_RevokeSubscriptionByNotOwner(
        address payer,
        address notPayer,
        uint256 amount,
        uint32 renewalFrequency
    ) external subscribed(payer, amount, renewalFrequency, 1) {
        vm.assume(payer != notPayer);
        uint256 subscriptionId = 0;

        vm.expectRevert("Subscription is not yours.");
        vm.prank(notPayer);
        terminal.revokeSubscription(subscriptionId);
    }

    function test_RevertIf_RevokeRevokedSubscription(address payer, uint256 amount, uint32 renewalFrequency)
        external
        subscribed(payer, amount, renewalFrequency, 1)
    {
        vm.prank(payer);
        terminal.revokeSubscription(0);

        vm.expectRevert("Subscription is revoked.");
        terminal.revokeSubscription(0);
    }
}

contract TerminalCollectSubscriptionTest is SubscriptionBase {
    event SubscriptionPaid(address indexed payer, uint256 subscriptionId);

    uint256 internal subscriptionId = 0;

    function setUp() public override {
        super.setUp();
        terminal.grantRole(terminal.SUBSCRIPTION_MANAGER(), address(this));
    }

    function test_CollectSubscription(address payer, uint256 amount, uint32 renewalFrequency)
        external
        subscribed(payer, amount, renewalFrequency, 2)
    {
        vm.warp(block.timestamp + renewalFrequency);
        vm.expectEmit();
        emit SubscriptionPaid(payer, subscriptionId);
        terminal.collectSubscription(subscriptionId);
        Subscription memory expectedSubscription =
            Subscription(renewalFrequency, uint64(block.timestamp), payer, amount, tokenAddress, false);
        Subscription memory subscription = terminal.getSubscription(subscriptionId);
        _compareSubscriptions(subscription, expectedSubscription);
    }

    function test_RevertIf_CollectAlreadyCollectedSubscription(address payer, uint256 amount, uint32 renewalFrequency)
        external
        subscribed(payer, amount, renewalFrequency, 2)
    {
        vm.assume(renewalFrequency != 0);
        vm.expectRevert("Renewal already collected.");
        terminal.collectSubscription(subscriptionId);
    }

    function test_RevertIf_CollectSubscriptionWithInsufficientAllowance(
        address payer,
        uint256 amount,
        uint32 renewalFrequency
    ) external subscribed(payer, amount, renewalFrequency, 1) {
        vm.expectRevert("ERC20: insufficient allowance");
        vm.warp(block.timestamp + renewalFrequency);
        terminal.collectSubscription(subscriptionId);
    }

    function test_RevertIf_CollectSubscriptionWhenContractPaused(address payer, uint256 amount, uint32 renewalFrequency)
        external
        subscribed(payer, amount, renewalFrequency, 2)
    {
        vm.warp(block.timestamp + renewalFrequency);
        terminal.grantRole(terminal.PAUSE_ROLE(), address(this));
        terminal.pause();
        vm.expectRevert("Pausable: paused");
        terminal.collectSubscription(subscriptionId);
    }

    function test_RevertIf_CollectSubscriptionByNotManager(
        address payer,
        address notOwner,
        uint256 amount,
        uint32 renewalFrequency
    ) external subscribed(payer, amount, renewalFrequency, 2) {
        vm.assume(notOwner != address(this));
        vm.expectRevert(_getAccessControlRevertMessage(payer, terminal.SUBSCRIPTION_MANAGER()));
        vm.prank(payer);
        terminal.collectSubscription(subscriptionId);
    }

    function test_RevertIf_CollectRevokedSubscription(address payer, uint256 amount, uint32 renewalFrequency)
        external
        subscribed(payer, amount, renewalFrequency, 2)
    {
        vm.prank(payer);
        terminal.revokeSubscription(subscriptionId);
        vm.warp(block.timestamp + renewalFrequency);
        vm.expectRevert("Subscription is revoked.");
        terminal.collectSubscription(subscriptionId);
    }
}

contract TerminalPauseTest is TerminalBase {
    function setUp() public override {
        super.setUp();
        terminal.grantRole(terminal.PAUSE_ROLE(), address(this));
    }

    function test_Pause() external {
        assertTrue(!terminal.paused());
        terminal.pause();
        assertTrue(terminal.paused());
    }

    function test_Unpause() external {
        assertTrue(!terminal.paused());
        terminal.pause();
        assertTrue(terminal.paused());
        terminal.unpause();
        assertTrue(!terminal.paused());
    }
}

contract TerminalWithdrawTest is TerminalBase, PreparationUtils {
    function setUp() public override {
        super.setUp();
        terminal.grantRole(terminal.WITHDRAW_ROLE(), address(this));
    }

    function test_Withdraw(uint256 amount)
        external
        nativeTokenTransferPrepared(address(terminal), address(0x12345), amount)
    {
        address payable receiver = payable(address(0x12345));
        vm.assume(amount != 0);

        deal(address(terminal), amount);
        assertEq(address(terminal).balance, amount);
        assertEq(receiver.balance, 0);

        terminal.withdraw(receiver);

        assertEq(address(terminal).balance, 0);
        assertEq(receiver.balance, amount);
    }

    function test_RevertIf_WithdrawToZeroAddress(uint256 amount) external {
        deal(address(terminal), amount);
        assertEq(address(terminal).balance, amount);
        vm.expectRevert("Receiver is zero address.");
        terminal.withdraw(payable(address(0)));
    }

    function test_RevertIf_WithdrawAmountIsZero(address payable receiver) external {
        assumeNotZeroAddress(receiver);
        assertEq(address(terminal).balance, 0);
        vm.expectRevert("Insufficient balance to withdraw.");
        terminal.withdraw(receiver);
    }

    function test_RevertIf_WithdrawByNotManager(address payable receiver) external {
        vm.assume(address(terminal) != receiver);
        vm.assume(address(this) != receiver);

        vm.expectRevert(_getAccessControlRevertMessage(receiver, terminal.WITHDRAW_ROLE()));
        vm.prank(receiver);
        terminal.withdraw(receiver);
    }
}

contract TerminalWithdrawTokensTest is TerminalBase, PreparationUtils {
    function setUp() public override {
        super.setUp();
        terminal.grantRole(terminal.WITHDRAW_ROLE(), address(this));
    }

    function test_WithdrawTokens(address receiver, uint256 amount)
        external
        tokenTransferPrepared(address(terminal), receiver, token, amount, 0, amount)
    {
        terminal.withdrawTokens(receiver, tokenAddress, amount);
    }

    function test_RevertIf_WithdrawTokensToZeroAddress(uint256 amount) external {
        vm.expectRevert("receiver is zero address");
        terminal.withdrawTokens(address(0), tokenAddress, amount);
    }
}
