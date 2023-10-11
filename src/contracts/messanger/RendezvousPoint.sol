// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IdentityChecker} from "contracts/did/IdentityChecker.sol";

import {IIdentityManager} from "interfaces/did/IIdentityManager.sol";
import {IModuleStorage} from "interfaces/messanger/IModuleStorage.sol";
import {IRendezvousPoint} from "interfaces/messanger/IRendezvousPoint.sol";

/**
 * @title Rendezvous Point Contract
 * @notice This contract is a place for on-chain message exchange.
 */
contract RendezvousPoint is IRendezvousPoint, IdentityChecker {
    IModuleStorage private immutable moduleStorage;

    constructor(IModuleStorage _moduleStorage, IIdentityManager _identityManager) IdentityChecker(_identityManager) {
        moduleStorage = _moduleStorage;
    }

    /// @inheritdoc IRendezvousPoint
    function requestRendezvous(address _senderNxid, address _receiverNxid, string calldata _message)
        external
        onlyAdmin(_senderNxid)
    {
        moduleStorage.checkApproval(_receiverNxid, _senderNxid);
        emit NewRequest(_receiverNxid, _message);
    }
}
