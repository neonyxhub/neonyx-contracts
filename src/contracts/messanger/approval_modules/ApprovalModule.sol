// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import {IdentityChecker} from "contracts/did/IdentityChecker.sol";

import {IIdentityManager} from "interfaces/did/IIdentityManager.sol";
import {IApprovalModule} from "interfaces/messanger/approval_modules/IApprovalModule.sol";

/**
 * @title ApprovalModule
 * @notice An contract that implements the IApprovalModule interface and provides common functionality for approval modules.
 */
abstract contract ApprovalModule is IApprovalModule, ERC165, IdentityChecker {
    string public name;

    /**
     * @dev Constructor that sets the name of the approval module.
     * @param _name The name of the approval module.
     */
    constructor(string memory _name, IIdentityManager _identityManager) IdentityChecker(_identityManager) {
        name = _name;
    }

    /// @inheritdoc IApprovalModule
    function isApproved(address, /* _targetNxid */ address /* _nxidToCheck */ ) external view virtual returns (bool);

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IApprovalModule).interfaceId || super.supportsInterface(interfaceId);
    }
}
