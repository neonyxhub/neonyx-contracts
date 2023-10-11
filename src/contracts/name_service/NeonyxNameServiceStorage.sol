// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {strings} from "stringutils/strings.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {INeonyxNameServiceStorage, Name} from "interfaces/name_service/INeonyxNameServiceStorage.sol";

// @title Neonyx Names contract
// @notice Dynamically generated NFT contract which represents a user name
contract NeonyxNameServiceStorage is INeonyxNameServiceStorage, ERC721A, AccessControl, ReentrancyGuard {
    using strings for string;

    mapping(bytes32 nameHash => Name nameData) private names; // keccak256(name) => Name struct
    mapping(uint256 tokenId => string name) private tokenIdsNames;
    mapping(address user => uint256 tokenId) private defaultNames;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor() ERC721A("Neonyx Name Service", "NNX") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    /// @inheritdoc INeonyxNameServiceStorage
    function getName(string memory name) external view returns (Name memory) {
        return names[getNameHash(name)];
    }

    /// @inheritdoc INeonyxNameServiceStorage
    function getNameHash(string memory name) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(name));
    }

    /// @inheritdoc INeonyxNameServiceStorage
    function getHolderDefaultName(address _holder) external view returns (string memory) {
        return tokenIdsNames[defaultNames[_holder]];
    }

    /// @inheritdoc INeonyxNameServiceStorage
    function getNameOwner(string memory name) external view returns (address) {
        return getNameOwner(getNameHash(name));
    }

    /// @inheritdoc INeonyxNameServiceStorage
    function getNameOwner(bytes32 nameBytes) public view returns (address) {
        Name storage nameData = names[nameBytes];
        if (nameData.ttl < block.timestamp) {
            return address(0);
        }
        return nameData.owner;
    }

    /// @inheritdoc INeonyxNameServiceStorage
    function editDefaultName(string memory name) external {
        require(names[getNameHash(name)].owner == msg.sender, "You do not own the selected name");
        _editDefaultName(msg.sender, name);
    }

    function _editDefaultName(address owner, string memory name) internal {
        defaultNames[owner] = names[getNameHash(name)].tokenId;
        emit DefaultNameChanged(owner, name);
    }

    /// @inheritdoc INeonyxNameServiceStorage
    function increaseTtl(string calldata name, uint256 _timeToAdd) external onlyRole(ADMIN_ROLE) {
        // if name is not expired
        bytes32 nameBytes = getNameHash(name);
        if (names[nameBytes].ttl > block.timestamp) {
            names[nameBytes].ttl += _timeToAdd;
        } else {
            names[nameBytes].ttl = block.timestamp + _timeToAdd;
        }
    }

    /// @inheritdoc INeonyxNameServiceStorage
    function checkName(string memory name) public pure {
        require(bytes(name).length > 0, "You can't mint empty name");
        require(strings.count(name.toSlice(), strings.toSlice(".")) == 0, "There should be no dots in the name");
        require(strings.count(name.toSlice(), strings.toSlice(" ")) == 0, "There should be no spaces in the name");
    }

    function mintName(string memory name, address nameHolder, uint256 _timeToExpiration)
        external
        onlyRole(ADMIN_ROLE)
        nonReentrant
        returns (uint256)
    {
        checkName(name);

        Name storage newName = names[getNameHash(name)];

        // if a token with this name already exists, we burn the old one before minting a new one
        if (newName.tokenId != 0) {
            delete tokenIdsNames[newName.tokenId];
            _burn(newName.tokenId);
        }

        _safeMint(nameHolder, 1);

        // store data in Name struct
        newName.tokenId = _nextTokenId() - 1;
        newName.owner = nameHolder;
        newName.ttl = block.timestamp + _timeToExpiration;

        tokenIdsNames[_nextTokenId() - 1] = name;

        if (defaultNames[nameHolder] == 0) {
            _editDefaultName(nameHolder, name); // if default name is not set for that holder, set it now
        }

        emit NameCreated(nameHolder, name);

        return _nextTokenId() - 1;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning.
     */
    function _beforeTokenTransfers(address from, address to, uint256 tokenId, uint256 /* quantity */ )
        internal
        virtual
        override
    {
        // run on every transfer but not on mint
        if (from != address(0)) {
            // change holder address in Name struct
            names[getNameHash(tokenIdsNames[tokenId])].owner = to;

            if (defaultNames[to] == 0) {
                // if default name is not set for that holder, set it now
                defaultNames[to] = tokenId;
            }

            if (defaultNames[from] == tokenId) {
                // if previous owner had this name as default, unset it as default
                defaultNames[from] = 0;
            }
        }
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
