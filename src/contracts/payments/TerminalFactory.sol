// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Terminal} from "./Terminal.sol";

/**
 * @title TerminalFactory Contract
 * @notice A contract for creating instances of the Terminal contract.
 */
contract TerminalFactory {
    /**
     * @dev Event emitted when a new Terminal contract is created.
     * @param terminal The address of the created Terminal contract.
     */
    event TerminalCreated(address indexed terminal);

    /**
     * @notice Creates a new Terminal contract.
     * @return The address of the created Terminal contract.
     */
    function createTerminal() public returns (address) {
        Terminal terminal = new Terminal();
        terminal.grantRole(terminal.DEFAULT_ADMIN_ROLE(), msg.sender);
        terminal.renounceRole(terminal.DEFAULT_ADMIN_ROLE(), address(this));
        emit TerminalCreated(address(terminal));
        return address(terminal);
    }
}
