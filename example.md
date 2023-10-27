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
