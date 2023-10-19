// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {console} from 'forge-std/console.sol';
import {Test} from 'forge-std/Test.sol';
import {XERC20} from '../contracts/XERC20.sol';
import {XERC20Lockbox} from '../contracts/XERC20Lockbox.sol';
import {XERC20Factory, IXERC20Factory} from '../contracts/XERC20Factory.sol';
import {Script} from 'forge-std/Script.sol';
import {ScriptingLibrary} from './ScriptingLibrary/ScriptingLibrary.sol';

contract MultichainCreateXERC20 is Script, ScriptingLibrary {
  uint256 public deployer = vm.envUint('DEPLOYER_PRIVATE_KEY');
  string[] public chains = ['POLYGON_RPC', 'OPTIMISM_RPC', 'GOERLI_RPC'];
  string public temp = vm.readLine('./solidity/scripts/ScriptingLibrary/FactoryAddress.txt');

  address public fact = toAddress(temp);
  XERC20Factory public factory = XERC20Factory(fact);
  // NOTE: This is an array of the addresses of the ERC20 contract you are deploying the lockbox for, if you dont want to deploy a lockbox leave this as is
  // NOTE: You must add the token address of your token for each chain you are deploying to in order of how the chains are listed in chains.txt, if no address is listed we will not deplyo a lockbox
  address[] public erc20 = [address(0)];
  // NOTE: Please also for each add a boolean to this array, if you are deploying a lockbox for the native token set it to true, if not set it to false for each iteration of an erc20
  bool[] public isNative = [false];

  function run() public {
    address[] memory tokens = new address[](chains.length);
    address[][] memory bridges = new address[][](chains.length);
    uint256[][] memory minterLimits = new uint256[][](chains.length);
    uint256[][] memory burnLimits = new uint256[][](chains.length);

    // Below are all the variables you need to change when deploying your XERC20 token
    string memory name = 'Test Token';
    string memory symbol = 'TST';

    for (uint256 i; i < chains.length; i++) {
      bridges[i] = new address[](0);
      minterLimits[i] = new uint256[](0);
      burnLimits[i] = new uint256[](0);

      // NOTE: Here is a commented example of how you would add this, dont forget to update the length to be whatever you want
      // burnLimits[i][0] = 1e18;
      // minteerLimits[i][0] = 1e18;
      // bridges[i][0] = msg.sender;

      vm.createSelectFork(vm.rpcUrl(vm.envString(chains[i])));
      address _erc20 = i < erc20.length ? erc20[i] : address(0);
      bool _isNative = i < isNative.length ? isNative[i] : false;
      vm.startBroadcast(deployer);
      // If this chain does not have a factory we will revert
      require(
        keccak256(address(factory).code) != keccak256(address(0).code), 'There is no factory deployed on this chain'
      );

      address xerc20 = factory.deployXERC20(name, symbol, minterLimits[i], burnLimits[i], bridges[i]);
      address lockbox;
      if (_erc20 != address(0) && !_isNative) {
        lockbox = factory.deployLockbox(xerc20, _erc20, _isNative);
      }
      vm.stopBroadcast();
      console.log(chains[i], 'token deployed to: ', xerc20);
      console.log(chains[i], 'lockbox deployed to: ', lockbox);
      tokens[i] = xerc20;
    }

    if (chains.length > 1) {
      for (uint256 i = 1; i < chains.length; i++) {
        vm.assume(tokens[i - 1] == tokens[i]);
        vm.assume(keccak256(tokens[i - 1].code) == keccak256(tokens[i].code));
      }
    }
  }
}
