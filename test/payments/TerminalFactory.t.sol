// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "contracts/payments/TerminalFactory.sol";
import "forge-std/Test.sol";

contract TerminalFactoryTest is Test {
    event TerminalCreated(address indexed terminal);

    TerminalFactory public terminalFactory;

    function setUp() external {
        terminalFactory = new TerminalFactory();
        emit log_address(address(terminalFactory));
    }

    function testCreateTerminal(address owner) external {
        vm.assume(owner != address(terminalFactory));
        vm.expectEmit(false, false, false, false);
        emit TerminalCreated(address(0));
        vm.prank(owner);
        Terminal terminal = Terminal(terminalFactory.createTerminal());
        assertTrue(terminal.hasRole(terminal.DEFAULT_ADMIN_ROLE(), owner));
    }
}
