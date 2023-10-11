// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IdentityChecker} from "contracts/did/IdentityChecker.sol";

import {IIdentityManager} from "interfaces/did/IIdentityManager.sol";
import {IApprovalModule} from "interfaces/messanger/approval_modules/IApprovalModule.sol";
import {IModuleStorage} from "interfaces/messanger/IModuleStorage.sol";

contract ModuleStorage is IModuleStorage, IdentityChecker {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => uint256) private requiredApprovals;
    mapping(address => EnumerableSet.AddressSet) private whitelistModules;
    mapping(address => EnumerableSet.AddressSet) private blacklistModules;

    constructor(IIdentityManager _identityManager) IdentityChecker(_identityManager) {}

    /**
     * @notice Modifier to check if an address is an approval module.
     * @param _nxidToCheck The address to check.
     */
    modifier onlyApprovalModule(address _nxidToCheck) {
        require(
            ERC165Checker.supportsInterface(_nxidToCheck, type(IApprovalModule).interfaceId),
            "Contract is not approval module."
        );
        _;
    }

    /// @inheritdoc IModuleStorage
    function setRequiredApprovals(address _userNxid, uint256 _requiredApprovals) external onlyAdmin(_userNxid) {
        requiredApprovals[_userNxid] = _requiredApprovals;
    }

    /// @inheritdoc IModuleStorage
    function getWhitelistModules(address _nxidToCheck) external view returns (address[] memory) {
        return whitelistModules[_nxidToCheck].values();
    }

    /// @inheritdoc IModuleStorage
    function getBlacklistModules(address _nxidToCheck) external view returns (address[] memory) {
        return blacklistModules[_nxidToCheck].values();
    }

    /// @inheritdoc IModuleStorage
    function addWhitelistModule(address _userNxid, address _moduleAddress)
        external
        onlyApprovalModule(_moduleAddress)
        onlyAdmin(_userNxid)
    {
        bool success = whitelistModules[msg.sender].add(_moduleAddress);
        require(success, "This module is already in whitelist.");
        emit WhitelistModuleAdded(_moduleAddress);
    }

    /// @inheritdoc IModuleStorage
    function addBlacklistModule(address _userNxid, address _moduleAddress)
        external
        onlyApprovalModule(_moduleAddress)
        onlyAdmin(_userNxid)
    {
        bool success = blacklistModules[_userNxid].add(_moduleAddress);
        require(success, "This module is already in blacklist.");
        emit BlacklistModuleAdded(_moduleAddress);
    }

    /// @inheritdoc IModuleStorage
    function removeWhitelistModule(address _userNxid, address _moduleToRemove) external onlyAdmin(_userNxid) {
        bool success = whitelistModules[_userNxid].remove(_moduleToRemove);
        require(success, "This module is not in your whitelist.");
        emit WhitelistModuleRemoved(_moduleToRemove);
    }

    /// @inheritdoc IModuleStorage
    function removeBlacklistModule(address _userNxid, address _moduleToRemove) external onlyAdmin(_userNxid) {
        bool success = blacklistModules[_userNxid].remove(_moduleToRemove);
        require(success, "This module is not in your blacklist.");
        emit BlacklistModuleRemoved(_moduleToRemove);
    }

    /// @inheritdoc IModuleStorage
    function getRequiredApprovals(address _userNxid) public view returns (uint256 _requiredApprovals) {
        // if amount of approvals is not specified correctly then set it to the number of modules
        // Example:
        // User got 3 modules and required approvals set to 0 => _requiredApprovals will be 3
        // User got 3 modules and required approvals set to 1 => _requiredApprovals will be 1
        // User got 3 modules and required approvals set to 5 => _requiredApprovals will be 3
        // User got 3 modules and required approvals set to 3 => _requiredApprovals will be 3
        // User got 0 modules and required approvals set to 0 => _requiredApprovals will be 0
        if (requiredApprovals[_userNxid] != 0 && requiredApprovals[_userNxid] <= whitelistModules[_userNxid].length()) {
            _requiredApprovals = requiredApprovals[_userNxid];
        } else {
            _requiredApprovals = whitelistModules[_userNxid].length();
        }
    }

    /// @inheritdoc IModuleStorage
    function isWhitelisted(address _targetNxid, address _nxidToCheck) public view returns (bool) {
        address[] memory modules = whitelistModules[_targetNxid].values();
        uint256 approvedAmount;
        for (uint256 i; i < modules.length; i++) {
            if (IApprovalModule(modules[i]).isApproved(_targetNxid, _nxidToCheck)) {
                approvedAmount += 1;
            }
        }

        uint256 _requiredApprovals = getRequiredApprovals(_targetNxid);

        // if user got no modules no one is whitelisted and function will return false
        return approvedAmount >= _requiredApprovals && _requiredApprovals > 0;
    }

    /// @inheritdoc IModuleStorage
    function isBlacklisted(address _targetNxid, address _nxidToCheck) public view returns (bool) {
        address[] memory modules = blacklistModules[_targetNxid].values();
        for (uint256 i = 0; i < modules.length; i++) {
            IApprovalModule approvalModule = IApprovalModule(modules[i]);
            if (approvalModule.isApproved(_targetNxid, _nxidToCheck)) {
                return true;
            }
        }
        return false;
    }

    /// @inheritdoc IModuleStorage
    function checkApproval(address _targetNxid, address _nxidToCheck) external view {
        require(!isBlacklisted(_targetNxid, _nxidToCheck), "You are blacklisted.");
        require(isWhitelisted(_targetNxid, _nxidToCheck), "You are not whitelisted.");
    }
}
