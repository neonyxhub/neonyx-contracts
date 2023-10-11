// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IIdentityManager {
    event DIDOnchainControllerChanged(
        address indexed identity, address controller, uint256 expirationTimestamp, uint256 previousChange
    );

    event DIDAttributeChanged(
        address indexed identity, string key, string value, uint256 expirationTimestamp, uint256 previousChange
    );

    function lastChange(address _nxid) external view returns (uint256);

    function nonce(address _nxid) external view returns (uint256);

    function onchainControllers(address _nxid, address _controller) external view returns (uint256);

    /**
     * @notice Add an on-chain controller to a DID.
     * @param _nxid The DID for which the controller is being added.
     * @param _controller The controller address.
     * @param _expirationTimestamp The timestamp at which the controller expires.
     * @param _signature The signature to authorize the operation.
     */
    function addOnchainController(
        address _nxid,
        address _controller,
        uint256 _expirationTimestamp,
        bytes calldata _signature
    ) external;

    /**
     * @notice Revoke an on-chain controller from a DID.
     * @param _nxid The DID from which the controller is being revoked.
     * @param _controller The controller address to be revoked.
     * @param _signature The signature to authorize the operation.
     */
    function revokeOnchainController(address _nxid, address _controller, bytes calldata _signature) external;

    /**
     * @notice Set a DID attribute.
     * @param _nxid The DID for which the attribute is being set.
     * @param _controller The controller authorizing the attribute change.
     * @param _attributeKey The key of the attribute.
     * @param _attributeValue The value to set.
     * @param _expirationTimestamp The timestamp at which the attribute expires.
     * @param _signature The signature to authorize the operation.
     */
    function setAttribute(
        address _nxid,
        address _controller,
        string calldata _attributeKey,
        string calldata _attributeValue,
        uint256 _expirationTimestamp,
        bytes calldata _signature
    ) external;

    /**
     * @notice Revoke a DID attribute.
     * @param _nxid The DID for which the attribute is being revoked.
     * @param _controller The controller authorizing the attribute revocation.
     * @param _attributeKey The name of the attribute.
     * @param _attributeValue The value to remove.
     * @param _signature The signature to authorize the operation.
     */
    function revokeAttribute(
        address _nxid,
        address _controller,
        string calldata _attributeKey,
        string calldata _attributeValue,
        bytes calldata _signature
    ) external;

    /**
     * @notice Execute a transaction on behalf of a DID.
     * @param _nxid The DID authorizing the transaction.
     * @param _controller The controller authorizing the transaction.
     * @param _signature The signature to authorize the operation.
     * @param _target The target address of the transaction.
     * @param _data The transaction data.
     */
    function executeTransaction(
        address _nxid,
        address _controller,
        bytes calldata _signature,
        address _target,
        bytes4 _functionSelector,
        bytes calldata _data
    ) external payable returns (bytes memory);

    /**
     * @notice Get the data hash for a given DID and data.
     * @param _nxid The DID to generate hash
     * @param _data The to generate hash.
     * @return The data hash.
     */
    function getDataHash(address _nxid, bytes calldata _data) external view returns (bytes32);

    /**
     * @dev Get the ERC191 message hash for a given data hash.
     * @param _dataHash The data hash.
     * @return The message hash.
     */
    function getMessageHash(bytes32 _dataHash) external pure returns (bytes32);

    /**
     * @dev Get the ERC191 message hash for a given DID and data.
     * @param _nxid The DID to generate hash
     * @param _data The to generate hash.
     * @return The message hash.
     */
    function getMessageHash(address _nxid, bytes memory _data) external view returns (bytes32);
}
