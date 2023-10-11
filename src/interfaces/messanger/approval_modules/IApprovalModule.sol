// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IApprovalModule {
    /**
     * @notice Returns the name of the approval module.
     * @return The name of the approval module.
     */
    function name() external view returns (string memory);

    /**
     * @notice Checks if an address is approved.
     * @param _targetNxid The address of the user.
     * @param _nxidToCheck The address to check the approval for.
     * @return A boolean indicating whether the address is approved or not.
     */
    function isApproved(address _targetNxid, address _nxidToCheck) external view returns (bool);
}
