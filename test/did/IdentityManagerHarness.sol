// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IdentityManager} from "contracts/did/IdentityManager.sol";

contract IdentityManagerHarness is IdentityManager {
    /**
     * @dev Verify the signature of an operation.
     * @param nxid The DID for which the operation is authorized.
     * @param controller The controller authorizing the operation.
     * @param signature The signature authorizing the operation (inputsHash signed by controller).
     * @param inputs The hash of the initial function inputs.
     */
    function exposed_verifySignature(address nxid, address controller, bytes memory signature, bytes memory inputs)
        public
    {
        _verifySignature(nxid, controller, signature, inputs);
    }
}
