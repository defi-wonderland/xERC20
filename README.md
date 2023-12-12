# xERC20

xERC20 is a standard for bridged tokens. A common interface to be used across different implementations of bridges to keep liquidity concentrated and improve user experience on-chain.

### Contracts

_XERC20_: A standard for bridges to manage the same liquidity when bridging. It allows its owner to approve bridges and add limits to them for minting and burning the XERC20 token. The XERC20 standard is compatible with two different types of bridge behaviours, bridges calling mint/burn from the user (or other function names through adapters) and bridges that transfer from the user to the bridge contract. On the latter, XERC20 tokens that are received by the bridge get burned and when a bridge transfers tokens out, they get minted again.

_XERC20Lockbox_: The lockbox works as a wrapper of an ERC20. It mints XERC20 tokens at a 1:1 ratio when receiving ERC20 tokens and it unlocks the ERC20 the other way around. The lockbox can be deployed on any chain that has a canonical token representation, chains that do not currently have a canonical representation can avoid deploying a Lockbox and use the XERC20 as the default implementation for the chain.

_XERC20Factory_: The factory is used as a helper to deploy an xToken. It allows the owner to deploy the XERC20 and the Lockbox in one transaction while keeping the same token address on every chain used.

### Architectural Spec

<img width="863" src="./assets/architectural-specs.png?raw=true">

<sup>\*The adapter included is an example into how it would work. Any bridge can build their own.</sup>

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

> ℹ️ Notice: \_Please ensure that all private keys (PKs) are prefixed with `0x` before using or submitting them. This prefix is necessary for proper formatting and compatibility.*

```
Example:
- Correct: `0x123abc...`
- Incorrect: `123abc...`
```

You will need to set your custom `name` and `symbol` for your XERC20 to be deployed, no need to add an 'x' infront of it, the contract will do that for you. For more details check the section below.

## Setup Guide to Deploy an xERC20 Token

This guide provides a detailed, step-by-step process to deploy an xERC20 token using this repository. We will first demonstrate how to deploy the xERC20 token alone, and then we’ll cover the scenario in which you want to deploy both the xERC20 token and the lockbox.

## Deploying xERC20 Without the Lockbox

### 1. Navigate to the MultichainCreateXERC20 Script

Locate and open the `MultichainCreateXERC20.sol` file, which should be situated within the `solidity/scripts` directory.

### 2. Configure the Target Chains

Decide on which blockchains you want to deploy your token. For this example, we will choose Ethereum mainnet, Polygon, and Gnosis. Add the required chains to the `chains` array in the `MultichainCreateXERC20.sol` file like so:

```solidity
string[] public chains = ['MAINNET_RPC', 'POLYGON_RPC', 'GNOSIS_RPC'];
```

Ensure that you have the corresponding RPC URLs added in your .env file to support these networks. Refer to this section for more information on setting up your environment variables.

### 3. Set Token Name and Symbol

Update the token name and symbol in your smart contract. For this guide, we are setting the name of the token to "Setup Token" and the symbol to "SToken". Make the changes on lines 31 and 32 in your smart contract code.

> ℹ️ Important Note: An address cannot deploy a token with the same name and symbol more than once on any given chain. Ensure that you have not previously deployed a token with the same name or symbol using your address.

```solidity
string memory name = 'Setup Token';
string memory symbol = 'SToken';
```

Save your changes to proceed.

### 4. Compile Your Smart Contract

Ensure that everything in your smart contract is set up correctly and free of errors by compiling it with the following command:

```sh
yarn build
```

You should see a confirmation in your terminal, similar to the screenshot below:

![Screenshot 2023-10-27 at 1 59 00 PM](https://github.com/prathmeshkhandelwal1/Chat-App/assets/56167998/e05f8c07-ac4c-4a36-a9ae-05884ff5aad4)

### 5. Dry-Run Deployment

Before proceeding with the actual deployment of your token, it is crucial to perform a dry-run. This helps in verifying the deployment process and estimating the gas costs on all the selected chains. Run the following command to initiate a dry-run:

```sh
yarn run script:DeployXERC20
```

You will receive the xERC20 token address, transaction details, and gas estimates as shown in the screenshots below:

![Screenshot 2023-10-27 at 2 02 15 PM](https://github.com/prathmeshkhandelwal1/Chat-App/assets/56167998/fc24b67e-3123-43e4-b388-2b6237e150bc)

![Screenshot 2023-10-27 at 2 05 23 PM](https://github.com/prathmeshkhandelwal1/Chat-App/assets/56167998/0654c085-4f41-4cf0-b940-8030ba396fec)

### 6. Deploy Your xERC20 Token

You are now at the final step of the deployment process. With all the previous steps successfully completed, you are ready to deploy your xERC20 token to the selected blockchain networks. Run the following command to initiate the deployment:

```sh
yarn run script:DeployXERC20:broadcast
```

Congratulations! You have successfully deployed your xERC20 token. 🚀

## Deploying xERC20 + Lockbox
Integrating xERC20 with a Lockbox requires a few additional steps, yet the process remains straightforward. Prior to embarking on this journey, ensure that you have completed steps 1-3 from the previous section, focusing on code modifications.

Assuming you have navigated through the initial steps successfully, let’s dive into the integration of xERC20 with Lockbox:

### Decide on Chains for Your Lockbox
Identify the blockchain networks where your token is already deployed and cannot be converted to xERC20. On these specific networks, a Lockbox will be required to facilitate interactions.

## Configure Chains for Lockbox Integration
Next, in the same MultichainCreateXERC20.sol file, specify the canonical token addresses for the chains requiring a Lockbox. Here’s how to do it:

> ℹ️ Important Note: Ensure alignment between the address or canonical token and the chains array. For chains not requiring a Lockbox, you can either leave the address field blank or use the ZERO address.

```solidity
// Example:

// Chains for xERC20 deployment
string[] public chains = ['MAINNET_RPC', 'POLYGON_RPC', 'GNOSIS_RPC'];

// Canonical token addresses for Lockbox
// (assuming MAINNET requires a Lockbox, others do not)
address[] public erc20 = [
    address(0x123...abc), // Canonical token on MAINNET
    address(0),           // No Lockbox for POLYGON
    address(0)            // No Lockbox for GNOSIS
];

// Alternatively, focusing solely on MAINNET:
address[] public erc20 = [
    address(0x123...abc) // Canonical token on MAINNET
];
```

With everything now configured, proceed by following the steps outlined in the “Deploying xERC20 Without the Lockbox” section. This includes building and deploying your contracts, ensuring a seamless integration of xERC20 and Lockbox.

### Dry-Run Deployment with Lockbox Verification

Before deploying your xERC20 token along with the Lockbox, it’s essential to conduct a dry-run. This ensures everything is set up correctly and provides you with gas estimates for all selected chains, as well as the addresses for your xERC20 token and the Lockbox.

Run the following command to start the dry-run:

```sh
yarn run script:DeployXERC20
```

Upon completion, you will receive output detailing the xERC20 token address, the Lockbox address, transaction details, and gas estimates. Below is an example of what your terminal might display:

<img width="601" alt="Screenshot 2023-10-30 at 5 45 30 PM" src="https://github.com/prathmeshkhandelwal1/xERC20/assets/56167998/c89362e1-3daf-460b-8a9a-e01544c2aae7">

Here you can see lockbox addresses 🚀.

Now broadcast it and you are good to go.

The deployments are stored in ./broadcast

See the [Foundry Book for available options](https://book.getfoundry.sh/reference/forge/forge-create.html).
