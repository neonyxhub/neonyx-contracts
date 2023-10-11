// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {INeonyxNameServiceReserve} from "interfaces/name_service/INeonyxNameServiceReserve.sol";

contract NeonyxNameServiceReserve is INeonyxNameServiceReserve, AccessControl {
    mapping(bytes32 name => address owner) public reservations; // keccak256(loweredName) => owner
    bytes32 public constant RESERVE_MANAGER = keccak256("RESERVE_MANAGER");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(RESERVE_MANAGER, msg.sender);
    }

    /// @inheritdoc INeonyxNameServiceReserve
    function reserveName(string memory _name, address _owner) external onlyRole(RESERVE_MANAGER) {
        reservations[keccak256(abi.encodePacked(_name))] = _owner;
    }

    /// @inheritdoc INeonyxNameServiceReserve
    function isOwner(string memory _name, address _owner) external view returns (bool) {
        bytes32 _nameBytes = keccak256(abi.encodePacked(_name));

        // if name is not reserved, then everyone is the owner of the reservation
        if (reservations[_nameBytes] == address(0) || reservations[_nameBytes] == _owner) {
            return true;
        }
        return false;
    }
}
