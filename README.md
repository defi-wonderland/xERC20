# xERC20

xERC20 is a standard for bridged tokens. A common interface to be used across different implementations of bridges to keep liquidity concentrated and improve user experience on-chain. 

### Contracts

*XERC20*: A standard for bridges to manage the same liquidity when bridging. It allows its owner to approve bridges and add limits to them for minting and burning the XERC20 token. The XERC20 standard is compatible with two different types of bridge behaviours, bridges calling mint/burn from the user (or other function names through adapters) and bridges that transfer from the user to the bridge contract. On the latter, XERC20 tokens that are received by the bridge get burned and when a bridge transfers tokens out, they get minted again.

*XERC20Lockbox*: The lockbox works as a wrapper of an ERC20. It mints XERC20 tokens at a 1:1 ratio when receiving ERC20 tokens and it unlocks the ERC20 the other way around. The lockbox can be deployed on any chain that has a canonical token representation, chains that do not currently have a canonical representation can avoid deploying a Lockbox and use the XERC20 as the default implementation for the chain.

*XERC20Factory*: The factory is used as a helper to deploy an xToken. It allows the owner to deploy the XERC20 and the Lockbox in one transaction while keeping the same token address on every chain used.

### Architectural Spec
<img width="863" src="./assets/architectural-specs.png?raw=true">

<sup>*The adapter included is an example into how it would work. Any bridge can build their own.</sup>

### Flows
<img width="1269" src="./assets/flows.png?raw=true">

## Setup

1. Install Foundry by following the instructions from [their repository](https://github.com/foundry-rs/foundry#installation).
2. Copy the `.env.example` file to `.env` and fill in the variables
3. Install the dependencies by running : `yarn install && forge install`

## Build

The default way to build the code is suboptimal but fast, you can run it via:

```bash
yarn build
```

In order to build a more optimized code ([via IR](https://docs.soliditylang.org/en/v0.8.15/ir-breaking-changes.html#solidity-ir-based-codegen-changes)), run:

```bash
yarn build:optimized
```

## Running tests

Unit tests should be isolated from any externalities, while E2E usually run in a fork of the blockchain. In this boilerplate you will find example of both.

In order to run both unit and E2E tests, run:

```bash
yarn test
```

In order to just run unit tests, run:

```bash
yarn test:unit
```

In order to run unit tests and run way more fuzzing than usual (5x), run:

```bash
yarn test:unit:deep
```

In order to just run e2e tests, run:

```bash
yarn test:e2e
```

In order to check your current code coverage, run:

```bash
yarn coverage
```

> **⚠ WARNING: Forge coverage is having some issues...**  
> As stated in this [github issue](https://github.com/foundry-rs/foundry/issues/2165), checking the code coverage with Forge when using abstract contract is not currently working.

<br>

## Deploy & verify

### Setup

Configure the `.env` variables.

Change the parameters inside the corresponding scripts you are running to deploy your XERC20

You will need to set your custom `name` and `symbol` for your XERC20 to be deployed, no need to add an 'x' infront of it, the contract will do that for you.

If you choose to deploy with some bridges to already have permissions to mint/burn you will also have the option to add that, and inside `MultichainCreateXERC20.sol` you will see notes on how to do so

On line 14 of the `MultichainCreateXERC20.sol` and line 13 of the `MultichainDeploy.sol`, you will need to add the names of all the `.env` variables you would like to deploy to inside the `chains` array.

### Deploy your XERC20

1. To simulate the deployment of an XERC20  you can run
```bash
yarn script:DeployXERC20
```
2. To deploy an XERC20 to all the chains you have in the array you can run
```bash
yarn script:DeployXERC20:broadcast
```

The deployments are stored in ./broadcast

See the [Foundry Book for available options](https://book.getfoundry.sh/reference/forge/forge-create.html).
