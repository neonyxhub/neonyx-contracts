// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct Subscription {
    // renewal frequency is much lower than timestamps that's why we can use uint32 for it.
    uint32 renewalFrequency;
    // uint64 max value is 18,446,744,073,709,551,615 which is more than enough for timestamp
    uint64 lastPaymentTimestamp;
    address payer;
    uint256 amount;
    address token;
    bool revoked;
}

interface ITerminal {
    event SubscriptionCreated(address indexed payer, uint256 subscriptionId);
    event SubscriptionPaid(address indexed payer, uint256 subscriptionId);
    event PaymentReceived(address indexed sender, address indexed token, uint256 amount);

    function SUBSCRIPTION_MANAGER() external view returns (bytes32);

    function PAUSE_ROLE() external view returns (bytes32);

    function WITHDRAW_ROLE() external view returns (bytes32);

    function subscriptionAmount() external view returns (uint256);

    function getSubscription(uint256 subscriptionId) external view returns (Subscription memory);

    function getWhitelistedTokens() external view returns (address[] memory);

    /**
     * @notice Marks token as whitelisted.
     * @param _tokenAddress token address to whitelist.
     */
    function addWhitelistedToken(address _tokenAddress) external;

    /**
     * @notice Removes token from whitelisted.
     * @param _tokenAddress token address to remove from whitelisted.
     */
    function removeWhitelistedToken(address _tokenAddress) external;

    /**
     * @notice Receives a payment.
     * @param _tokenAddress The address of the payment token.
     * @param _amount The amount of the payment.
     */
    function orderPayment(address _tokenAddress, uint256 _amount) external payable;

    /**
     * @notice Creates a subscription.
     * @param _tokenAddress The address of the payment token.
     * @param _amount The amount of the payment.
     * @param _renewalFrequency Minimum time between renewals.
     */
    function subscribe(address _tokenAddress, uint256 _amount, uint32 _renewalFrequency) external;

    /**
     * @notice Revokes subscription.
     * @param _subscriptionId subscription ID
     */
    function revokeSubscription(uint256 _subscriptionId) external;

    /**
     * @notice Collects subscription payment.
     * @param _subscriptionId subscription ID
     */
    function collectSubscription(uint256 _subscriptionId) external;

    /**
     * @notice Gets list of subscriptions for specific user.
     * @param _user user address
     * @return list of subscriptions ids
     */
    function getUserSubscriptions(address _user) external view returns (uint256[] memory);

    /**
     * @notice Pauses contract functionality.
     */
    function pause() external;

    /**
     * @notice Unpauses contract functionality.
     */
    function unpause() external;

    /**
     * @notice Allows the contract admin to withdraw the contract's balance in ETH.
     * @param _receiver The address to receive the withdrawn amount.
     */
    function withdraw(address payable _receiver) external;

    /**
     * @notice Allows the contract admin to withdraw ERC20 tokens.
     * @param _receiver The address to receive the withdrawn tokens.
     * @param _tokenAddress The address of the ERC20 token to be withdrawn.
     * @param _amount The amount of tokens to be withdrawn.
     */
    function withdrawTokens(address _receiver, address _tokenAddress, uint256 _amount) external;
}
