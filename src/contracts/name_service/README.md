# Neonyx Name Service

## Name Service Storage

### Overview

`NeonyxNameService.sol` is a contract that represents a __Username__ in the Neonyx ecosystem. It
allows owners to mint domain names as non-fungible tokens (NFTs) and manage ownership.

### Why?

We want users to get names in our ecosystem.

### Contract Responsibilities

- Mint a new domain name as an NFT.
- Save the default domain for a user.
- Handle the transfer of domain ownership.

## Name Service Payments

### Overview

`NeonyxNameServicePayments.sol` is a contract which manages payments including mint and renewal fees.

### Why?

Names are not free and they require renewals. This contract is needed to collect these payments.

### Names

If name is not already in use, everyone can mint this name. Also names can be reserved for specific user.
Names with spaces and dots can't be minted, every name without these symbols is mintable.
But there are some off-chain rules (ex. name should be in lowercase) and it's possible that name is mintable but is not
valid for resolving. The list of rules is not implemented yet.

## Name Service Reserve

### Overview

`NeonyxNameServiceReserve.sol` is a storage of reserved names. All the reserved names are stored in this contract.

### Why?

We want to premint the names of popular persons and present them as gift for registration in our platform.
Also, we want to premint some good names to give away them or sell them through auctions.
This contract is needed to save some gas and not to mint real names but just reserve them.

## Name Service Subnames

### Overview

`NeonyxNameServiceSubnames.sol` is a contract that represents a __Subnames__ in the Neonyx ecosystem.
Subname becomes unresolvable as soon as name expires or an owner changes.
We use a __Name__ owner in __Subname__ data hash
that's why if an owner changes => hash changes => __Subname__ becomes unresolvable.


### Why?

Subnames is a good feature to have. 

### Subnames

__Subnames__ are same as __Names__ but there are no on-chain rules for __Subnames__.
__Name__ owner can mint any __Subname__ he is like.
__Subnames__ becomes unresolvable if an owner changes.
__Subname__ should be resolvable to something. But it isn't implemented yet.



