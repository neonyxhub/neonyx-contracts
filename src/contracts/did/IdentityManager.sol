// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import {IIdentityManager} from "interfaces/did/IIdentityManager.sol";

/**
 * @title IdentityManager
 * @notice A contract for managing decentralized identifiers (DIDs) and associated controllers.
 */
contract IdentityManager is IIdentityManager {
    using Address for address;

    mapping(address nxid => uint256 blockNumber) public lastChange;
    mapping(address nxid => uint256 nonce) public nonce;
    mapping(address nxid => mapping(address controller => uint256 expirationTimestamp)) public onchainControllers;

    /**
     * @dev Modifier to ensure that an operation is authorized using a valid signature.
     * @param _nxid The DID for which the operation is authorized.
     * @param _controller The controller authorizing the operation.
     * @param _signature The signature authorizing the operation (inputsHash signed by controller).
     * @param _data The hash of the initial function inputs.
     */
    modifier authorized(address _nxid, address _controller, bytes memory _signature, bytes memory _data) {
        // If msg.sender is the NXID, no signature checks are needed.
        // If controller is nxid then NXID itself performs an action.
        if (msg.sender == _nxid || onchainControllers[_nxid][msg.sender] > block.timestamp && _nxid != _controller) {}
        // If msg.sender is not the NXID or valid controller, verify the signature.
        else {
            // only nxid itself or valid controller can perform actions with DID
            require(
                _nxid == _controller || onchainControllers[_nxid][_controller] > block.timestamp,
                "This controller is not authorized."
            );
            _verifySignature(_nxid, _controller, _signature, _data);
        }
        _;
    }

    /// @inheritdoc IIdentityManager
    function addOnchainController(
        address _nxid,
        address _controller,
        uint256 _expirationTimestamp,
        bytes memory _signature
    )
        external
        authorized(
            _nxid,
            _nxid,
            _signature,
            abi.encode(address(this), this.addOnchainController.selector, _controller, _expirationTimestamp)
        )
    {
        _changeOnchainController(_nxid, _controller, _expirationTimestamp);
    }

    /// @inheritdoc IIdentityManager
    function revokeOnchainController(address _nxid, address _controller, bytes memory _signature)
        external
        authorized(_nxid, _nxid, _signature, abi.encode(address(this), this.revokeOnchainController.selector, _controller))
    {
        _changeOnchainController(_nxid, _controller, 0);
    }

    /// @inheritdoc IIdentityManager
    function setAttribute(
        address _nxid,
        address _controller,
        string calldata _attributeKey,
        string calldata _attributeValue,
        uint256 _expirationTimestamp,
        bytes memory _signature
    )
        external
        authorized(
            _nxid,
            _controller,
            _signature,
            abi.encode(address(this), this.setAttribute.selector, _attributeKey, _attributeValue, _expirationTimestamp)
        )
    {
        _changeAttribute(_nxid, _attributeKey, _attributeValue, _expirationTimestamp);
    }

    /// @inheritdoc IIdentityManager
    function revokeAttribute(
        address _nxid,
        address _controller,
        string calldata _attributeKey,
        string calldata _attributeValue,
        bytes memory _signature
    )
        external
        authorized(
            _nxid,
            _controller,
            _signature,
            abi.encode(address(this), this.revokeAttribute.selector, _attributeKey, _attributeValue)
        )
    {
        _changeAttribute(_nxid, _attributeKey, _attributeValue, 0);
    }

    /// @inheritdoc IIdentityManager
    function executeTransaction(
        address _nxid,
        address _controller,
        bytes memory _signature,
        address _target,
        bytes4 _functionSelector,
        bytes calldata _data
    )
        external
        payable
        authorized(_nxid, _controller, _signature, abi.encode(_target, _functionSelector, _data))
        returns (bytes memory)
    {
        // to ensure that function will be called with correct nxid we construct call data on-chain.
        bytes memory _fullData = bytes.concat(abi.encodeWithSelector(_functionSelector, _nxid), _data);
        return _target.functionCallWithValue(_fullData, msg.value);
    }

    /// @inheritdoc IIdentityManager
    function getDataHash(address _nxid, bytes memory _data) public view returns (bytes32) {
        return _getDataHash(_nxid, _data, nonce[_nxid], block.chainid);
    }

    /// @inheritdoc IIdentityManager
    function getMessageHash(bytes32 _dataHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes1(0x19), bytes1(0x45), "thereum Signed Message:\n32", _dataHash));
    }

    /// @inheritdoc IIdentityManager
    function getMessageHash(address _nxid, bytes memory _data) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(bytes1(0x19), bytes1(0x45), "thereum Signed Message:\n32", getDataHash(_nxid, _data))
        );
    }

    /**
     * @dev Internal function to change an on-chain controller for a DID.
     * @param _nxid The DID for which the controller is being changed.
     * @param _controller The controller address.
     * @param _expirationTimestamp The timestamp at which the controller expires.
     */
    function _changeOnchainController(address _nxid, address _controller, uint256 _expirationTimestamp) internal {
        onchainControllers[_nxid][_controller] = _expirationTimestamp;
        emit DIDOnchainControllerChanged(_nxid, _controller, _expirationTimestamp, lastChange[_nxid]);
        lastChange[_nxid] = block.number;
    }

    /**
     * @dev Internal function to change a DID attribute.
     * @param _nxid The DID for which the attribute is being changed.
     * @param _attributeKey The name of the attribute.
     * @param _attributeValue The value of the attribute.
     * @param _expirationTimestamp The timestamp at which the attribute expires.
     */
    function _changeAttribute(
        address _nxid,
        string calldata _attributeKey,
        string calldata _attributeValue,
        uint256 _expirationTimestamp
    ) internal {
        emit DIDAttributeChanged(_nxid, _attributeKey, _attributeValue, _expirationTimestamp, lastChange[_nxid]);
        lastChange[_nxid] = block.number;
    }

    /**
     * @dev Get the data hash for a given DID and data, including nonce and chain ID.
     * @param _nxid The DID to generate hash.
     * @param _data The data to generate hash.
     * @param _nonce The nonce value.
     * @param _chainId The chain ID.
     * @return The data hash.
     */
    function _getDataHash(address _nxid, bytes memory _data, uint256 _nonce, uint256 _chainId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_data, _nxid, _nonce, _chainId));
    }

    /**
     * @dev Verify the signature of an operation.
     * @param _nxid The DID for which the operation is authorized.
     * @param _controller The controller authorizing the operation.
     * @param _signature The signature authorizing the operation (inputsHash signed by controller).
     * @param _data The hash of the initial function inputs.
     */
    function _verifySignature(address _nxid, address _controller, bytes memory _signature, bytes memory _data)
        internal
    {
        // 1. nxid - NXID is used to prevent signature reuse with different NXID.
        // 2. data - data is used to prevent replay attacks by using valid signature to call wrong function with wrong data.
        // 3. nonce - Nonce is one time used value to prevent replay attacks and ensure message sequence.
        // 4. chainid - https://eips.ethereum.org/EIPS/eip-155
        bytes32 _dataHash = _getDataHash(_nxid, _data, nonce[_nxid]++, block.chainid);
        bytes32 _messageHash = getMessageHash(_dataHash);
        require(SignatureChecker.isValidSignatureNow(_controller, _messageHash, _signature), "Signature is not valid.");
    }
}
