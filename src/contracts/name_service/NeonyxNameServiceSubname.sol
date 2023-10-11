// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IdentityChecker} from "contracts/did/IdentityChecker.sol";

import {IIdentityManager} from "interfaces/did/IIdentityManager.sol";
import {INeonyxNameServiceStorage} from "interfaces/name_service/INeonyxNameServiceStorage.sol";
import {INeonyxNameServiceSubname, Subname} from "interfaces/name_service/INeonyxNameServiceSubname.sol";

contract NeonyxNameServiceSubname is INeonyxNameServiceSubname, IdentityChecker {
    INeonyxNameServiceStorage public immutable nameService;

    mapping(bytes32 subnameHash => Subname subnameData) private subnames; // keccak256(subname, parentOwner) => Subname struct
    mapping(bytes32 simpleSubnameHash => bytes32 parentHash) private parents; // keccak256(subname) => keccak256(parent)

    constructor(INeonyxNameServiceStorage _nameService, IIdentityManager _identityManger)
        IdentityChecker(_identityManger)
    {
        nameService = _nameService;
    }

    /// @inheritdoc INeonyxNameServiceSubname
    function resolveSubname(string memory _subname) external view returns (Subname memory) {
        bytes32 _subnameHash = keccak256(abi.encodePacked(_subname));
        address _prefixOwner = nameService.getNameOwner(parents[_subnameHash]);

        return subnames[keccak256(abi.encodePacked(_subnameHash, _prefixOwner))];
    }

    /// @inheritdoc INeonyxNameServiceSubname
    function addSubname(address _ownerNxid, string memory _subname, string memory _prefix)
        external
        onlyAdmin(_ownerNxid)
    {
        address _prefixOwner = nameService.getNameOwner(_prefix);

        require(_prefixOwner == _ownerNxid, "You are not prefix owner.");
        nameService.checkName(_subname);

        bytes32 _simpleSubnameHash = keccak256(abi.encodePacked(_prefix, ".", _subname));

        if (parents[_simpleSubnameHash] == bytes32(0)) {
            parents[_simpleSubnameHash] = keccak256(abi.encodePacked(_prefix));
        }

        bytes32 _subnameHash = keccak256(abi.encodePacked(_simpleSubnameHash, _prefixOwner));
        subnames[_subnameHash].owner = _prefixOwner;
    }
}
