// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ITerminal, Subscription} from "interfaces/payments/ITerminal.sol";

/**
 * @title Terminal Contract
 * @notice A contract that facilitates payment processing.
 */
contract Terminal is ITerminal, Pausable, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant SUBSCRIPTION_MANAGER = keccak256("SUBSCRIPTION_MANAGER");
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    EnumerableSet.AddressSet private whitelistedTokens;

    uint256 public subscriptionAmount;
    mapping(uint256 subscriptionId => Subscription subscriptionData) private subscriptions;
    mapping(address userAddress => EnumerableSet.UintSet subscriptions) private userSubscriptions;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @inheritdoc ITerminal
    function getWhitelistedTokens() external view returns (address[] memory) {
        return whitelistedTokens.values();
    }

    /// @inheritdoc ITerminal
    function getSubscription(uint256 subscriptionId) external view returns (Subscription memory) {
        return subscriptions[subscriptionId];
    }

    /// @inheritdoc ITerminal
    function addWhitelistedToken(address _tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bool success = whitelistedTokens.add(_tokenAddress);
        require(success, "Token is already whitelisted.");
    }

    /// @inheritdoc ITerminal
    function removeWhitelistedToken(address _tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bool success = whitelistedTokens.remove(_tokenAddress);
        require(success, "Token is not whitelisted.");
    }

    /// @inheritdoc ITerminal
    function orderPayment(address _tokenAddress, uint256 _amount) external payable whenNotPaused {
        require(_amount > 0 || msg.value > 0, "Amount must be greater than zero.");

        // if payer sends both native token and ERC20 token then payee will process transaction as native token payment.
        if (msg.value > 0) {
            _amount = msg.value;
            _tokenAddress = address(0);
            // We check that token is whitelisted inside ifs to lower revert gas units in case of token transfer.
            require(whitelistedTokens.contains(_tokenAddress), "Token is not whitelisted.");
        } else {
            require(whitelistedTokens.contains(_tokenAddress), "Token is not whitelisted.");
            IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
        }

        emit PaymentReceived(msg.sender, _tokenAddress, _amount);
    }

    /// @inheritdoc ITerminal
    function subscribe(address _tokenAddress, uint256 _amount, uint32 _renewalFrequency)
        external
        whenNotPaused
        nonReentrant
    {
        require(whitelistedTokens.contains(_tokenAddress), "Token is not whitelisted.");
        require(_amount > 0, "Amount should be positive.");
        Subscription storage subscription = subscriptions[subscriptionAmount];
        subscription.token = _tokenAddress;
        subscription.amount = _amount;
        subscription.payer = msg.sender;
        subscription.renewalFrequency = _renewalFrequency;
        // first payment will be done later in this transaction that's why we set last payment timestamp in past
        subscription.lastPaymentTimestamp = uint64(block.timestamp) - uint64(_renewalFrequency);

        userSubscriptions[msg.sender].add(subscriptionAmount);
        _collectSubscription(subscriptionAmount);

        emit SubscriptionCreated(msg.sender, subscriptionAmount++);
    }

    /**
     * @dev Modifier to check that a subscription is not revoked.
     * @param _subscriptionId subscription ID
     */
    modifier notRevoked(uint256 _subscriptionId) {
        require(!subscriptions[_subscriptionId].revoked, "Subscription is revoked.");
        _;
    }

    /// @inheritdoc ITerminal
    function revokeSubscription(uint256 _subscriptionId) external notRevoked(_subscriptionId) {
        require(subscriptions[_subscriptionId].payer == msg.sender, "Subscription is not yours.");
        subscriptions[_subscriptionId].revoked = true;
        userSubscriptions[msg.sender].remove(_subscriptionId);
    }

    /// @inheritdoc ITerminal
    function collectSubscription(uint256 _subscriptionId)
        external
        onlyRole(SUBSCRIPTION_MANAGER)
        whenNotPaused
        nonReentrant
    {
        _collectSubscription(_subscriptionId);
    }

    function _collectSubscription(uint256 _subscriptionId) internal notRevoked(_subscriptionId) {
        Subscription storage subscription = subscriptions[_subscriptionId];
        require(
            subscription.lastPaymentTimestamp + subscription.renewalFrequency <= block.timestamp,
            "Renewal already collected."
        );
        subscription.lastPaymentTimestamp += subscription.renewalFrequency;
        IERC20 tokenContract = IERC20(subscription.token);
        tokenContract.safeTransferFrom(subscription.payer, address(this), subscription.amount);
        emit SubscriptionPaid(subscription.payer, _subscriptionId);
    }

    /// @inheritdoc ITerminal
    function getUserSubscriptions(address _user) external view returns (uint256[] memory) {
        return userSubscriptions[_user].values();
    }

    /// @inheritdoc ITerminal
    function pause() external onlyRole(PAUSE_ROLE) {
        _pause();
    }

    /// @inheritdoc ITerminal
    function unpause() external onlyRole(PAUSE_ROLE) {
        _unpause();
    }

    /// @inheritdoc ITerminal
    function withdraw(address payable _receiver) external onlyRole(WITHDRAW_ROLE) {
        require(_receiver != address(0), "Receiver is zero address.");
        require(address(this).balance > 0, "Insufficient balance to withdraw.");
        _receiver.transfer(address(this).balance);
    }

    /// @inheritdoc ITerminal
    function withdrawTokens(address _receiver, address _tokenAddress, uint256 _amount)
        external
        onlyRole(WITHDRAW_ROLE)
    {
        require(_receiver != address(0), "receiver is zero address");
        IERC20 tokenContract = IERC20(_tokenAddress);
        tokenContract.safeTransfer(_receiver, _amount);
    }
}
