// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {NeonyxNameServiceReserve} from "contracts/name_service/NeonyxNameServiceReserve.sol";
import "forge-std/Test.sol";

contract NeonyxNameReserveTest is Test {
    NeonyxNameServiceReserve internal nameServiceReserve;
    string internal nameExample = "name";

    function setUp() external {
        nameServiceReserve = new NeonyxNameServiceReserve();
    }

    function test_ReserveName() external {
        assertEq(nameServiceReserve.reservations(keccak256(abi.encodePacked(nameExample))), address(0));
        assertTrue(nameServiceReserve.isOwner(nameExample, address(this)));

        nameServiceReserve.reserveName(nameExample, address(this));

        assertEq(nameServiceReserve.reservations(keccak256(abi.encodePacked(nameExample))), address(this));
        assertTrue(nameServiceReserve.isOwner(nameExample, address(this)));
    }

    function test_IsOwnerIfSomeoneReserved(address notOwner) external {
        vm.assume(address(this) != notOwner);
        nameServiceReserve.reserveName(nameExample, address(this));

        assertTrue(nameServiceReserve.isOwner(nameExample, address(this)));
        assertFalse(nameServiceReserve.isOwner(nameExample, notOwner));
    }
}
