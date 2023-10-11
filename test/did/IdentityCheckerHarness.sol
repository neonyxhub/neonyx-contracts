// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "contracts/did/IdentityChecker.sol";

contract IdentityCheckerHarness is IdentityChecker {
    constructor(IIdentityManager identityManager) IdentityChecker(identityManager) {}

    function exposed_OnlyAdmin(address nxid) public view onlyAdmin(nxid) returns (bool) {
        return true;
    }
}
