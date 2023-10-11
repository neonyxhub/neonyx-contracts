// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct Name {
    address owner;
    uint256 tokenId;
    uint256 ttl;
}

interface INeonyxNameServiceStorage {
    event NameCreated(address indexed owner, string fullName);
    event DefaultNameChanged(address indexed user, string defaultName);

    /**
     * @notice Retrieves the Name struct associated with a given name
     * @param name The name for which the Name struct is to be retrieved
     * @return The Name struct associated with the given name
     */
    function getName(string memory name) external view returns (Name memory);

    /**
     * @dev Generates the hash for a given name
     * @param name The name for which the hash is to be generated
     * @return The hash of the given name
     */
    function getNameHash(string memory name) external pure returns (bytes32);

    /**
     * @notice Retrieves the default name of a holder
     * @param _holder The address of the holder
     * @return The default name associated with the holder
     */
    function getHolderDefaultName(address _holder) external view returns (string memory);

    /**
     * @notice Retrieves the owner of a given name
     * @param name The name for which the owner is to be retrieved
     * @return The address of the owner of the given name
     */
    function getNameOwner(string memory name) external view returns (address);

    /**
     * @notice Retrieves the owner of a given name
     * @param nameHash The name hash for which the owner is to be retrieved
     * @return The address of the owner of the given name
     */
    function getNameOwner(bytes32 nameHash) external view returns (address);

    /**
     * @notice Increases the Time To Live (TTL) for a given name
     * @param name The name for which the TTL should be increased
     * @param _timeToAdd The amount of time to add to the TTL
     */
    function increaseTtl(string calldata name, uint256 _timeToAdd) external;

    /**
     * @notice Checks if provided name is valid
     * @param name name to check
     */
    function checkName(string memory name) external pure;

    /**
     * @notice Mints a new NFT representing a name
     * @param name The name to mint
     * @param nameHolder The address that will hold the NFT
     * @param _timeToExpiration Time until the name's expiration
     * @return The tokenId of the minted NFT
     */
    function mintName(string memory name, address nameHolder, uint256 _timeToExpiration) external returns (uint256);

    /**
     * @notice Edits the default name for msg.sender
     * @param name New default name
     */
    function editDefaultName(string memory name) external;
}
