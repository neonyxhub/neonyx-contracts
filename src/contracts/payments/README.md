## Terminal Contract

### Overview

`Terminal.sol` is a contract that facilitates payment processing. It allows users to create and manage subscriptions and
send payments. The contract supports whitelisting of payment tokens and provides role-based
access control for various functionalities.

### Why?

Terminal is needed in every business to take payments. This terminal allows receiving payments or users subscribing. 

### Contract Roles

The contract uses OpenZeppelin's `AccessControl` library to manage roles:

- `DEFAULT_ADMIN_ROLE`: The default admin role, assigned to the contract deployer.
- `PAUSE_ROLE`: The role that can pause and unpause contract functionality.
- `WITHDRAW_ROLE`: The role that can withdraw contract's balance and ERC20 tokens.
- `SUBSCRIPTION_MANAGER`: The role that can collect subscription payments.

### Subscriptions

To initiate a subscription, users must first approve the contract to spend a specified amount of tokens on their behalf.
After approval, users can subscribe to the service, and the contract will have the ability to withdraw the approved
tokens periodically, according to the subscription terms. The contract's logic ensures that the `Terminal` can't
withdraw subscription payments more frequently than what was specified by the user.

### Events

The contract emits the following events:

- `SubscriptionCreated`: Triggered when a new subscription is created.
- `SubscriptionPaid`: Triggered when a subscription payment is collected.
- `PaymentReceived`: Triggered when a payment is received.


