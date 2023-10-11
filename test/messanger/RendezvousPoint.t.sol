// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IdentityManager} from "contracts/did/IdentityManager.sol";
import {ModuleStorage} from "contracts/messanger/ModuleStorage.sol";
import {RendezvousPoint} from "contracts/messanger/RendezvousPoint.sol";
import {AcceptEveryone} from "contracts/messanger/approval_modules/AcceptEveryone.sol";
import "forge-std/Test.sol";

contract RendezvousPointTest is Test {
    event NewRequest(address indexed receiver, string message);

    RendezvousPoint internal rendezvousPoint;
    ModuleStorage internal moduleStorage;
    AcceptEveryone internal acceptEveryoneModule;
    IdentityManager internal identityManager;

    function setUp() public {
        identityManager = new IdentityManager();
        moduleStorage = new ModuleStorage(identityManager);
        rendezvousPoint = new RendezvousPoint(moduleStorage, identityManager);
        acceptEveryoneModule = new AcceptEveryone(identityManager);
    }

    modifier whitelistEveryoneModuleAdded() {
        moduleStorage.addWhitelistModule(address(this), address(acceptEveryoneModule));
        _;
    }

    function test_RequestRendezvous(address senderNxid) external whitelistEveryoneModuleAdded {
        string memory message = "Some message";
        vm.expectEmit();
        emit NewRequest(address(this), message);
        vm.prank(senderNxid);
        rendezvousPoint.requestRendezvous(senderNxid, address(this), message);
    }
}
