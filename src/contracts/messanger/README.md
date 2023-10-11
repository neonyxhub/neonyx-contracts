# Messanger contracts

## Module storage

### Overview

`ModuleStorage.sol` is a contract responsible for managing modules.
Other contracts can interact with `ModuleStorage` to check approval for certain actions.

### Why?

Module storage is one place to manage your approvals. Module storage can be implemented in different contracts. 
And not only contracts, Module storage can be used for off-chain approvals. 
Module storage is contract to answer a simple question: is Approved or not?

### Modules

Modules are used to provide custom functionality to your experience.

These modules follow standardized protocol, allowing developers to create custom modules that integrate seamlessly.

### Whitelist and Blacklist

Each module can be used as a whitelist or blacklist option.

- If a user is blacklisted by any of the modules, they are prevented from sending requests. 
- If a user is not whitelisted by any of the whitelist modules, they are unable to send requests.

In summary, a user can only send a request if they are not blacklisted by any of the __Blacklist Modules__ and are
whitelisted by at least one (this value is specific for each receiver) of the __Whitelist modules.__ This mechanism
ensures that requests are only processed from users who meet the necessary approval conditions.

The combination of whitelist and blacklist modules provides a comprehensive approach to managing user requests, enabling
fine-grained control over access within the __Messanger__.

## RendezvousPoint

### Overview

`RendezvousPoint.sol` - A contract that allows for the creation and management of requests using approval modules. It
supports whitelisting and blacklisting of approval modules.

### Why?

The name speaks for itself. Rendezvous point is a meeting place with someone unknown. 
It's a place where you can find everyone, and everyone knows about this place. 

### Rendezvous Request

Rendezvous request is used for on-chain key exchange. Message must be encrypted with [keyAgreement](https://docs.attest.sh/) to ensure
that only `NXID` owner can process this request.

### Contract Responsibilities

- Creation and management of requests using approval modules.

### Notes

- This contract is modules-based, allowing you to create your own modules or use already deployed contracts that
  implement the `IApprovalModule` functionality.

## Approval Module

### Overview

`ApprovalModule.sol` is a contract that implements the `IApprovalModule` interface and provides common
functionality for approval modules.

### Why?

Approval modules are needed to answer a question: is approved or not? 
The reason for this decision can be everything that you wrote in code. 
It can be a simple manual approval or more complex decision based on certificates, activity or something else that is on-chain.

### Approval Process

The isApproved function is called for each request to a user. It is a view function, meaning it can't change blockchain
state. This design decision was made for the following reasons:

1. `isApproved` is predictable
2. Gas saving
3. Simplified user-interface (data inputs are not needed)
4. Off-chain request processing

### Contract Responsibilities

1. Check if an address is approved.

### Notes

- You can find some realizations in our repository.