// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IModuleStorage {
    event WhitelistModuleAdded(address indexed moduleAddress);
    event BlacklistModuleAdded(address indexed moduleAddress);
    event WhitelistModuleRemoved(address indexed moduleAddress);
    event BlacklistModuleRemoved(address indexed moduleAddress);

    /**
     * @notice Function to get required approvals amount.
     * @param _userNxid User nxid to get required approvals.
     * @return _requiredApprovals Amount of approvals to pass check.
     */
    function getRequiredApprovals(address _userNxid) external view returns (uint256 _requiredApprovals);

    /**
     * @notice Returns the list of whitelist modules.
     * @param _nxidToCheck User nxid to get whitelist modules.
     * @return An array of whitelist module addresses.
     */
    function getWhitelistModules(address _nxidToCheck) external view returns (address[] memory);

    /**
     * @notice Returns the list of blacklist modules.
     * @param _nxidToCheck User nxid to get blacklist modules.
     * @return An array of blacklist module addresses.
     */
    function getBlacklistModules(address _nxidToCheck) external view returns (address[] memory);

    /**
     * @notice Function to set approvals amount to get approved by modules.
     * @param _userNxid User nxid to perform an action.
     * @param _requiredApprovals Required amount to get approval.
     */
    function setRequiredApprovals(address _userNxid, uint256 _requiredApprovals) external;

    /**
     * @notice Add an approval module address to the whitelist of the specific user.
     * @param _userNxid User nxid to perform an action.
     * @param _moduleAddress The address of the approval module to add.
     */
    function addWhitelistModule(address _userNxid, address _moduleAddress) external;

    /**
     * @notice Add a module address to the blacklist for a specific user.
     * @param _userNxid User nxid to perform an action.
     * @param _moduleAddress The address of the approval module to add.
     */
    function addBlacklistModule(address _userNxid, address _moduleAddress) external;

    /**
     * @notice Remove a module address from the whitelist for a specific user.
     * @param _userNxid User nxid to perform an action.
     * @param _moduleToRemove The address of the approval module to remove.
     */
    function removeWhitelistModule(address _userNxid, address _moduleToRemove) external;

    /**
     * @notice Remove a module address from the blacklist for a specific user.
     * @param _userNxid User nxid to perform an action.
     * @param _moduleToRemove The address of the approval module to remove.
     */
    function removeBlacklistModule(address _userNxid, address _moduleToRemove) external;

    /**
     * @notice Checks if an address _nxidToCheck is whitelisted for a given user _targetNxid.
     * @param _targetNxid Nxid of modules owner.
     * @param _nxidToCheck The nxid to check.
     * @return A boolean indicating whether the address is whitelisted.
     */
    function isWhitelisted(address _targetNxid, address _nxidToCheck) external view returns (bool);

    /**
     * @notice Checks if an address _nxidToCheck is blacklisted for a given user _targetNxid.
     * @param _targetNxid Nxid of modules owner.
     * @param _nxidToCheck The nxid to check.
     * @return A boolean indicating if the address is blacklisted.
     */
    function isBlacklisted(address _targetNxid, address _nxidToCheck) external view returns (bool);

    /**
     * @notice Checks if an address is not blacklisted and approved by required amount of whitelist modules.
     * @param _targetNxid Message receiver to get modules.
     * @param _nxidToCheck The nxid to check.
     */
    function checkApproval(address _targetNxid, address _nxidToCheck) external view;
}
