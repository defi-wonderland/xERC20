// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {console} from 'forge-std/console.sol';
import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';
import {Test} from 'forge-std/Test.sol';
import {XERC20} from 'contracts/XERC20.sol';
import {XERC20Lockbox} from 'contracts/XERC20Lockbox.sol';
import {XERC20Factory, IXERC20Factory} from 'contracts/XERC20Factory.sol';
import {Script} from 'forge-std/Script.sol';

contract MultichainDeploy is Script {
  uint256 public deployer = vm.envUint('DEPLOYER_PRIVATE_KEY');
  string[] public chains = ['goerli', 'polygon', 'optimism'];

  function run() public {
    bytes32 _salt = keccak256(abi.encodePacked('XERC20Factory', msg.sender));
    address[] memory factories = new address[](chains.length);

    for (uint256 i; i < chains.length; i++) {
      vm.createSelectFork(vm.rpcUrl(chains[i]));
      vm.startBroadcast(deployer);
      address _deployedFactory = address(new XERC20Factory{salt: _salt}());
      vm.stopBroadcast();
      console.log(chains[i], 'factory deployed to:', address(_deployedFactory));
      factories[i] = _deployedFactory;
    }

    if (chains.length > 1) {
      for (uint256 i = 1; i < chains.length; i++) {
        vm.assume(factories[i - 1] == factories[i]);
        vm.assume(keccak256(factories[i - 1].code) == keccak256(factories[i].code));
      }
    }
  }
}
