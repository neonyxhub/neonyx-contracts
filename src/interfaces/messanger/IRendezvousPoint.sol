// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRendezvousPoint {
    event NewRequest(address indexed receiver, string message);

    /**
     * @notice Emits event with a request if approved by modules.
     * @param _senderNxid The nxid of the message sender.
     * @param _receiverNxid The nxid of the message receiver.
     * @param _message The message to send.
     */
    function requestRendezvous(address _senderNxid, address _receiverNxid, string calldata _message) external;
}
