// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct Subname {
    address owner;
}

interface INeonyxNameServiceSubname {
    /**
     * @notice Resolves a subname.
     * @param _subname subname to resolve.
     * @return Subname struct.
     */
    function resolveSubname(string memory _subname) external view returns (Subname memory);

    /**
     * @notice Add a new subname.
     * @param _subname subname to add.
     * @param _prefix name to be prefix.
     */
    function addSubname(address _ownerNxid, string memory _subname, string memory _prefix) external;
}
