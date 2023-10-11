// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IdentityManagerHarness.sol";
import "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {ExternalCalls} from "./ExternalCalls.sol";

contract IdentityManagerTestBase is Test {
    event DIDOnchainControllerChanged(
        address indexed identity, address controller, uint256 expirationTimestamp, uint256 previousChange
    );

    event DIDAttributeChanged(
        address indexed identity, string key, string value, uint256 expirationTimestamp, uint256 previousChange
    );

    IdentityManagerHarness internal identityManager;

    function setUp() public virtual {
        identityManager = new IdentityManagerHarness();
    }
}

contract IdentityManagerAddOnchainControllerTest is IdentityManagerTestBase {
    function test_AddOnchainController(address nxid, address controller, uint256 expirationTimestamp) external {
        assertEq(identityManager.onchainControllers(nxid, controller), 0);
        assertEq(identityManager.lastChange(nxid), 0);

        vm.expectEmit();
        emit DIDOnchainControllerChanged(nxid, controller, expirationTimestamp, identityManager.lastChange(nxid));
        vm.prank(nxid);
        identityManager.addOnchainController(nxid, controller, expirationTimestamp, bytes("0x"));
        assertEq(identityManager.onchainControllers(nxid, controller), expirationTimestamp);
        assertEq(identityManager.lastChange(nxid), block.number);
    }

    function test_AddOnchainControllerBySignature(address controller, address sender, uint256 expirationTimestamp)
        external
    {
        VmSafe.Wallet memory nxid = vm.createWallet("nxid");
        vm.assume(nxid.addr != sender);

        bytes32 messageHash = identityManager.getMessageHash(
            nxid.addr,
            abi.encode(
                address(identityManager), identityManager.addOnchainController.selector, controller, expirationTimestamp
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(nxid, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.prank(sender);
        identityManager.addOnchainController(nxid.addr, controller, expirationTimestamp, signature);
    }

    function test_RevertIf_ControllerTriesAddController(
        address nxid,
        address controller,
        address another_controller,
        uint256 expirationTimestamp
    ) external {
        vm.assume(nxid != controller && controller != another_controller);
        vm.prank(nxid);
        identityManager.addOnchainController(nxid, controller, 10000, bytes("0x"));
        vm.expectRevert("Signature is not valid.");
        vm.prank(controller);
        identityManager.addOnchainController(nxid, another_controller, expirationTimestamp, bytes("0x"));
    }
}

contract IdentityManagerRemoveOnchainControllerTest is IdentityManagerTestBase {
    function test_RevokeController(address nxid, address controller, uint256 expirationTimestamp) external {
        vm.startPrank(nxid);

        identityManager.addOnchainController(nxid, controller, expirationTimestamp, bytes("0x"));
        assertEq(identityManager.onchainControllers(nxid, controller), expirationTimestamp);

        vm.expectEmit();
        emit DIDOnchainControllerChanged(nxid, controller, 0, identityManager.lastChange(nxid));
        identityManager.revokeOnchainController(nxid, controller, bytes("0x0"));

        assertEq(identityManager.onchainControllers(nxid, controller), 0);

        vm.stopPrank();
    }

    function test_RevokeControllerBySignature(address sender, address controller, uint256 expirationTimestamp)
        external
    {
        VmSafe.Wallet memory nxid = vm.createWallet("nxid");
        vm.assume(nxid.addr != sender);
        vm.prank(nxid.addr);

        identityManager.addOnchainController(nxid.addr, controller, expirationTimestamp, bytes("0x"));
        assertEq(identityManager.onchainControllers(nxid.addr, controller), expirationTimestamp);

        bytes32 messageHash = identityManager.getMessageHash(
            nxid.addr,
            abi.encode(address(identityManager), identityManager.revokeOnchainController.selector, controller)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(nxid, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.prank(sender);
        identityManager.revokeOnchainController(nxid.addr, controller, signature);
    }

    function test_RevertIf_NotAuthorizedRevokeOnchainController(
        address nxid,
        address controller,
        uint256 expirationTimestamp
    ) external {
        vm.assume(nxid != controller);
        vm.prank(nxid);
        identityManager.addOnchainController(nxid, controller, expirationTimestamp, bytes("0x"));

        assertEq(identityManager.onchainControllers(nxid, controller), expirationTimestamp);
        vm.expectRevert("Signature is not valid.");
        vm.prank(controller);
        identityManager.revokeOnchainController(nxid, controller, bytes("0x"));
    }
}

contract IdentityManagerSetAttributeTest is IdentityManagerTestBase {
    function test_SetAttribute(address nxid, uint256 expirationTimestamp) external {
        string memory attributeKey = "assertionMethod";
        string memory attributeValue =
            "{'@id': 'https://w3id.org/security#assertionMethod', '@type': '@id', @container': '@set'}";
        assertEq(identityManager.lastChange(nxid), 0);
        vm.expectEmit();
        emit DIDAttributeChanged(
            nxid, attributeKey, attributeValue, expirationTimestamp, identityManager.lastChange(nxid)
        );
        vm.prank(nxid);
        identityManager.setAttribute(nxid, nxid, attributeKey, attributeValue, expirationTimestamp, bytes("0x0"));
        assertEq(identityManager.lastChange(nxid), block.number);
    }

    function test_SetAttributeBySignature(address sender, uint256 expirationTimestamp) external {
        string memory attributeKey = "assertionMethod";
        string memory attributeValue =
            "{'@id': 'https://w3id.org/security#assertionMethod', '@type': '@id', @container': '@set'}";
        VmSafe.Wallet memory nxid = vm.createWallet("nxid");
        vm.assume(nxid.addr != sender);
        bytes32 messageHash = identityManager.getMessageHash(
            nxid.addr,
            abi.encode(
                address(identityManager),
                identityManager.setAttribute.selector,
                attributeKey,
                attributeValue,
                expirationTimestamp
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(nxid, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.expectEmit();

        emit DIDAttributeChanged(
            nxid.addr, attributeKey, attributeValue, expirationTimestamp, identityManager.lastChange(nxid.addr)
        );
        vm.prank(sender);
        identityManager.setAttribute(nxid.addr, nxid.addr, attributeKey, attributeValue, expirationTimestamp, signature);
    }

    function test_SetAttributeByController(address nxid, address controller, uint256 expirationTimestamp) external {
        vm.assume(nxid != controller);
        vm.prank(nxid);
        identityManager.addOnchainController(nxid, controller, 10000, bytes(""));
        string memory attributeKey = "assertionMethod";
        string memory attributeValue =
            "{'@id': 'https://w3id.org/security#assertionMethod', '@type': '@id', @container': '@set'}";
        vm.expectEmit();
        emit DIDAttributeChanged(
            nxid, attributeKey, attributeValue, expirationTimestamp, identityManager.lastChange(nxid)
        );
        vm.prank(controller);
        identityManager.setAttribute(nxid, controller, attributeKey, attributeValue, expirationTimestamp, bytes("0x0"));
        assertEq(identityManager.lastChange(nxid), block.number);
    }
}

contract IdentityManagerRevokeAttributeTest is IdentityManagerTestBase {
    function test_RevokeAttribute(address nxid) external {
        string memory attributeKey = "assertionMethod";
        string memory attributeValue =
            "{'@id': 'https://w3id.org/security#assertionMethod', '@type': '@id', @container': '@set'}";
        assertEq(identityManager.lastChange(nxid), 0);
        vm.expectEmit();
        emit DIDAttributeChanged(nxid, attributeKey, attributeValue, 0, identityManager.lastChange(nxid));
        vm.prank(nxid);
        identityManager.revokeAttribute(nxid, nxid, attributeKey, attributeValue, bytes("0x0"));
        assertEq(identityManager.lastChange(nxid), block.number);
    }

    function test_RevokeAttributeBySignature(address sender) external {
        string memory attributeKey = "assertionMethod";
        string memory attributeValue =
            "{'@id': 'https://w3id.org/security#assertionMethod', '@type': '@id', @container': '@set'}";
        VmSafe.Wallet memory nxid = vm.createWallet("nxid");
        vm.assume(nxid.addr != sender);
        bytes32 messageHash = identityManager.getMessageHash(
            nxid.addr,
            abi.encode(address(identityManager), identityManager.revokeAttribute.selector, attributeKey, attributeValue)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(nxid, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.expectEmit();

        emit DIDAttributeChanged(nxid.addr, attributeKey, attributeValue, 0, identityManager.lastChange(nxid.addr));
        vm.prank(sender);
        identityManager.revokeAttribute(nxid.addr, nxid.addr, attributeKey, attributeValue, signature);
    }

    function test_RevokeAttributeByController(address nxid, address controller) external {
        vm.assume(nxid != controller);
        vm.prank(nxid);
        identityManager.addOnchainController(nxid, controller, 10000, bytes(""));
        string memory attributeKey = "assertionMethod";
        string memory attributeValue =
            "{'@id': 'https://w3id.org/security#assertionMethod', '@type': '@id', @container': '@set'}";
        vm.expectEmit();
        emit DIDAttributeChanged(nxid, attributeKey, attributeValue, 0, identityManager.lastChange(nxid));
        vm.prank(controller);
        identityManager.revokeAttribute(nxid, controller, attributeKey, attributeValue, bytes("0x0"));
        assertEq(identityManager.lastChange(nxid), block.number);
    }
}

contract IdentityManagerExecuteTransactionTest is IdentityManagerTestBase {
    ExternalCalls internal externalContract;

    function setUp() public override {
        super.setUp();
        externalContract = new ExternalCalls();
    }

    function test_ExecuteTransaction() external {
        VmSafe.Wallet memory nxid = vm.createWallet("nxid");
        assertEq(externalContract.score(nxid.addr), 0);
        uint8 amountToAdd = 2;
        bytes memory data =
            abi.encode(address(externalContract), externalContract.increaseScore.selector, abi.encode(amountToAdd));
        bytes32 dataHash = identityManager.getDataHash(nxid.addr, data);
        bytes32 messageHash = identityManager.getMessageHash(dataHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(nxid, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        identityManager.executeTransaction(
            nxid.addr,
            nxid.addr,
            signature,
            address(externalContract),
            externalContract.increaseScore.selector,
            abi.encode(amountToAdd)
        );
        assertEq(externalContract.score(nxid.addr), 2);
    }
}
