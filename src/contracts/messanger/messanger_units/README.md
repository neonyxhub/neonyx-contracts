# Messanger Units

## Club Registry

### Overview

`ClubRegistry.sol` is a contract that manages club memberships and reputations
using the [Ethereum Attestation Service (EAS)](https://docs.attest.sh/).
It allows clubs to define membership and reputation and track their members' reputations.

### Why?

`ClubRegistry.sol` is needed to add not only a quantitative but also qualitative reputation.
Reputation between different communities is different reputation.
Also, membership and reputation are sensitive data so we give an option to store it on-chain.
This contract also supports `ModuleStorage.sol`.
