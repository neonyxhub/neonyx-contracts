// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ApprovalModule} from "./ApprovalModule.sol";

import {IIdentityManager} from "interfaces/did/IIdentityManager.sol";

/**
 * @title PaymentAccept
 * @notice A contract that extends the ApprovalModule and allows approval based on payments.
 */
contract PaymentAccept is ApprovalModule, ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(address receiver => mapping(address tokenAddress => uint256 amount)) public requiredAmount;
    mapping(address receiver => mapping(address sender => bool isApproved)) public approved;

    event RequiredAmountSet(address indexed userNxid, address indexed tokenAddress, uint256 value);
    event AddressApproved(address indexed userNxid, address indexed approvedAddress);

    constructor(IIdentityManager _identityManager) ApprovalModule("Accept by payment", _identityManager) {}

    /**
     * @notice Sets the required payments amount for a specific user and token.
     * @param _userNxid The address of the user.
     * @param _tokenAddress The address of the token.
     * @param _value The required payments amount.
     */
    function setRequiredAmount(address _userNxid, address _tokenAddress, uint256 _value)
        external
        onlyAdmin(_userNxid)
    {
        requiredAmount[_userNxid][_tokenAddress] = _value;
        emit RequiredAmountSet(_userNxid, _tokenAddress, _value);
    }

    /**
     * @notice Sends all the payments to _receiverNxid and approves address if payment is correct.
     * @param _receiverNxid The address of the user.
     * @param _tokenAddress The address of the token.
     * @param _value The amount of tokens.
     */
    function sendPayment(address _senderNxid, address _receiverNxid, address _tokenAddress, uint256 _value)
        external
        payable
        onlyAdmin(_senderNxid)
        nonReentrant
    {
        require(!approved[_receiverNxid][_senderNxid], "Already approved.");

        // if user sent both native token and erc20 token then only native token payment will be processed.
        if (msg.value > 0) {
            _checkPayment(_receiverNxid, address(0), msg.value);
            payable(_receiverNxid).transfer(msg.value);
        } else {
            _checkPayment(_receiverNxid, _tokenAddress, _value);
            IERC20(_tokenAddress).safeTransferFrom(msg.sender, _receiverNxid, _value);
        }
        approved[_receiverNxid][_senderNxid] = true;
        emit AddressApproved(_receiverNxid, _senderNxid);
    }

    function _checkPayment(address _receiverNxid, address _tokenAddress, uint256 _value) internal view {
        require(requiredAmount[_receiverNxid][_tokenAddress] != 0, "This token is not approved by receiver.");
        require(
            requiredAmount[_receiverNxid][_tokenAddress] <= _value,
            "Insufficient amount sent. Please send the correct amount."
        );
    }

    /// @inheritdoc ApprovalModule
    function isApproved(address _targetNxid, address _nxidToCheck) external view override returns (bool) {
        return approved[_targetNxid][_nxidToCheck];
    }
}
