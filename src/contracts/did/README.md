# DID Contracts

## Identity Manager

### Overview

`IdentityManager.sol` is a contract responsible for
managing [decentralized identifiers (DIDs)](https://www.w3.org/TR/did-core/) and their associated
controllers.
It provides functionality for adding and revoking on-chain controllers, setting and revoking attributes,
and executing transactions on behalf of DIDs.
The contract ensures that operations are authorized using valid signatures.

### Why?

[Decentralized Identifiers (DIDs)](https://www.w3.org/TR/did-core/) are essential in decentralized systems for uniquely
identifying entities.
The IdentityManager contract serves as a management layer for DIDs, allowing controllers to make authorized changes
to DIDs and associated attributes.

### DID Document Resolution

Resolving a DID to a DID Document is an off-chain operation that involves using the `lastChange` call to determine the
latest change in the DID's attributes and then sequentially resolving `DIDAttributeChanged`
and `DIDOnchainControllerChanged` events from that point
backward until the `previousChange` is not 0. Here's a simplified step-by-step process:

1. **Get the Latest Change**:
   The resolver uses the lastChange call to determine the latest change in the attributes of
   the specified DID.

2. **Event Resolution**:
   Starting from the latest change, the resolver sequentially resolves `DIDAttributeChanged` events
   by querying each event one by one in reverse chronological order.
   The previousChange field in each event point to the previous change event.

3. **Data Collection**:
   For each resolved `DIDAttributeChanged` event, the resolver collects data related to the DID Document.
   This data may include public keys, service endpoints, attribute values, and other relevant information specified in
   the DID Document format.

4. **DID Document Construction**:
   Using the collected data from the resolved events, the resolver constructs a DID Document in
   the [JSON-LD](https://json-ld.org/) format.
   This document can be used for various purposes, including cryptographic operations, identity verification, and
   establishing trust with the DID controller.

### Signatures

To interact with the IdentityManager contract, you may need to generate a data hash, which is used in the signature
verification process.
This hash is a critical part of ensuring the security and authenticity of your operations
on decentralized identifiers (DIDs).

The data hash is computed using the following components:

- `nxid`: The decentralized identifier (DID) for which you want to perform an action.
- `data`: Data is byte structure of:
    - called address
    - function selector
    - function params.
- `nonce`: A unique nonce value associated with the operation. It helps prevent replay attacks and ensures the correct
  sequencing of messages.
- `chainId`: The Ethereum chain ID to which the operation is targeted. This ensures that the signature is specific to
  the intended Ethereum network.

This data hash is used for final hash which is implementation of [ERC-191](https://eips.ethereum.org/EIPS/eip-191).

## IdentityChecker Contract

### Overview

IdentityChecker.sol is a contract that provides access control functionality for managing user identities.
It allows access only to the owner of a user's identity (nxid) or a contract admin.