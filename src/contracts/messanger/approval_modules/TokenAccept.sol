// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ApprovalModule} from "./ApprovalModule.sol";

import {IIdentityManager} from "interfaces/did/IIdentityManager.sol";

/**
 * @title ClubAccept
 * @notice A contract that extends the ApprovalModule and allows approval based on tokens.
 */
contract TokenAccept is ApprovalModule {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address userNxid => EnumerableSet.AddressSet tokens) private whitelistedTokens;
    mapping(address userNxid => mapping(address tokenAddress => uint256 amount)) public requiredTokenAmounts;

    event TokenRemoved(address indexed userNxid, address indexed tokenAddress);
    event RequiredTokenAmountSet(address indexed userNxid, address indexed tokenAddress, uint256 requiredAmount);

    constructor(IIdentityManager _identityManager) ApprovalModule("Accept by token.", _identityManager) {}

    /**
     * @notice Adds a token to the club's token list.
     * @param _userNxid The address of the user.
     * @param _tokenAddress The address of the club token to add.
     * @param _requiredAmount Amount required for approval.
     */
    function setRequiredTokenAmount(address _userNxid, address _tokenAddress, uint256 _requiredAmount)
        external
        onlyAdmin(_userNxid)
    {
        require(requiredTokenAmounts[_userNxid][_tokenAddress] != _requiredAmount, "Required amount must change.");
        if (!whitelistedTokens[_userNxid].contains(_tokenAddress)) {
            whitelistedTokens[_userNxid].add(_tokenAddress);
        }
        requiredTokenAmounts[_userNxid][_tokenAddress] = _requiredAmount;
        emit RequiredTokenAmountSet(_userNxid, _tokenAddress, _requiredAmount);
    }

    /**
     * @notice Removes a token from the club's token list.
     * @param _userNxid The address of the user.
     * @param _tokenAddress The address of the club token to remove.
     */
    function removeToken(address _userNxid, address _tokenAddress) external onlyAdmin(_userNxid) {
        bool success = whitelistedTokens[_userNxid].remove(_tokenAddress);
        require(success, "Token is not in list.");
        requiredTokenAmounts[_userNxid][_tokenAddress] = 0;
        emit TokenRemoved(_userNxid, _tokenAddress);
    }

    /**
     * @notice Returns the list of whitelisted tokens tokens for a specific user.
     * @param _userNxid The address of the user.
     * @return An array of whitelisted tokens token addresses.
     */
    function getTokens(address _userNxid) public view returns (address[] memory) {
        return whitelistedTokens[_userNxid].values();
    }

    /// @inheritdoc ApprovalModule
    function isApproved(address _targetNxid, address _nxidToCheck) external view override returns (bool) {
        address[] memory tokens = getTokens(_targetNxid);
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 requiredTokenAmount = requiredTokenAmounts[_targetNxid][tokens[i]];
            if (IERC20(tokens[i]).balanceOf(_nxidToCheck) >= requiredTokenAmount) {
                return true;
            }
        }
        return false;
    }
}
