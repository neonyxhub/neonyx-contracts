# Neonyx Contracts

## Overview

Dive into the innovative world of Neonyx Contracts.

## 🚧 Development Disclaimer 🚧

Please be advised that the contracts within this repository are still in active development.
They have not undergone a complete security audit and, as such, may contain vulnerabilities or unintended behaviors.
We **strongly** discourage using them in any production environment or any environment with real assets at this time.

If you wish to experiment with the contracts, please do so with caution and at your own risk.
We appreciate any feedback, bug reports, or contributions to further improve the security and robustness of the code.

## Documentation

For a deeper understanding of each contract, navigate to the respective `src` folders where `README.md` files provide
further details.
The contracts themselves are amply documented for clarity.

## Deployments

Contracts are not deployed on any networks yet.

## Tests


| File                                                          | % Lines          | % Statements     | % Branches       | % Funcs         |
|---------------------------------------------------------------|------------------|------------------|------------------|-----------------|
| src/contracts/did/IdentityManager.sol                         | 100.00% (18/18)  | 100.00% (26/26)  | 100.00% (2/2)    | 100.00% (12/12) |
| src/contracts/messanger/ModuleStorage.sol                     | 100.00% (33/33)  | 100.00% (53/53)  | 100.00% (18/18)  | 100.00% (11/11) |
| src/contracts/messanger/RendezvousPoint.sol                   | 100.00% (2/2)    | 100.00% (2/2)    | 100.00% (0/0)    | 100.00% (1/1)   |
| src/contracts/messanger/approval_modules/AcceptEveryone.sol   | 100.00% (1/1)    | 100.00% (1/1)    | 100.00% (0/0)    | 100.00% (1/1)   |
| src/contracts/messanger/approval_modules/ApprovalModule.sol   | 100.00% (1/1)    | 100.00% (4/4)    | 100.00% (0/0)    | 100.00% (1/1)   |
| src/contracts/messanger/approval_modules/ManualAccept.sol     | 100.00% (8/8)    | 100.00% (12/12)  | 100.00% (4/4)    | 100.00% (4/4)   |
| src/contracts/messanger/approval_modules/MembershipAccept.sol | 100.00% (12/12)  | 100.00% (18/18)  | 100.00% (6/6)    | 100.00% (4/4)   |
| src/contracts/messanger/approval_modules/PaymentAccept.sol    | 100.00% (13/13)  | 100.00% (13/13)  | 87.50% (7/8)     | 100.00% (4/4)   |
| src/contracts/messanger/approval_modules/RejectEveryone.sol   | 100.00% (0/0)    | 100.00% (0/0)    | 100.00% (0/0)    | 100.00% (1/1)   |
| src/contracts/messanger/approval_modules/ReputationAccept.sol | 100.00% (15/15)  | 100.00% (21/21)  | 100.00% (8/8)    | 100.00% (4/4)   |
| src/contracts/messanger/approval_modules/TokenAccept.sol      | 100.00% (16/16)  | 100.00% (22/22)  | 100.00% (8/8)    | 100.00% (4/4)   |
| src/contracts/messanger/messanger_units/ClubRegistry.sol      | 100.00% (37/37)  | 100.00% (43/43)  | 100.00% (6/6)    | 100.00% (10/10) |
| src/contracts/name_service/NeonyxNameServicePayments.sol      | 100.00% (18/18)  | 100.00% (24/24)  | 100.00% (16/16)  | 100.00% (4/4)   |
| src/contracts/name_service/NeonyxNameServiceReserve.sol       | 100.00% (5/5)    | 100.00% (9/9)    | 100.00% (2/2)    | 100.00% (2/2)   |
| src/contracts/name_service/NeonyxNameServiceStorage.sol       | 100.00% (41/41)  | 100.00% (49/49)  | 100.00% (22/22)  | 100.00% (13/13) |
| src/contracts/name_service/NeonyxNameServiceSubname.sol       | 100.00% (11/11)  | 100.00% (17/17)  | 100.00% (4/4)    | 100.00% (2/2)   |
| src/contracts/payments/Terminal.sol                           | 100.00% (44/44)  | 100.00% (50/50)  | 100.00% (26/26)  | 100.00% (14/14) |
| src/contracts/payments/TerminalFactory.sol                    | 100.00% (5/5)    | 100.00% (7/7)    | 100.00% (0/0)    | 100.00% (1/1)   |



## Contributing

We welcome contributions to the Neonyx contracts!
If you have improvements, bug fixes, or new features, follow these steps:

1. Fork the repository.
2. Create a new branch for your changes.
3. Make your changes and test them.
4. Submit a pull request with a detailed description of your changes.
5. Please ensure that your contributions adhere to our coding and documentation standards.

## License

`Neonyx Contracts` is released under the [MIT License](LICENSE).