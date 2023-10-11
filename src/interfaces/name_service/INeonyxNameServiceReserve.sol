// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface INeonyxNameServiceReserve {
    function RESERVE_MANAGER() external view returns (bytes32);

    /**
     * @notice Reserves a name.
     * @param _name Name to reserve.
     * @param _owner Owner address to set.
     */
    function reserveName(string memory _name, address _owner) external;

    /**
     * @notice Checks if _owner is _name owner.
     * @param _name Name to check.
     * @param _owner Owner address to check.
     * @return is _owner a _name owner.
     */
    function isOwner(string memory _name, address _owner) external view returns (bool);
}
