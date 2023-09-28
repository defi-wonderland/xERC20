// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {console} from 'forge-std/console.sol';
import {Test} from 'forge-std/Test.sol';
import {XERC20Factory, IXERC20Factory} from '../contracts/XERC20Factory.sol';
import {Script} from 'forge-std/Script.sol';
import {ScriptingLibrary} from './ScriptingLibrary/ScriptingLibrary.sol';

contract MultichainDeploy is Script, ScriptingLibrary {
  uint256 public deployer = vm.envUint('DEPLOYER_PRIVATE_KEY');
  address constant CREATE2 = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
  string[] public chains = ['POLYGON_RPC', 'OPTIMISM_RPC', 'GOERLI_RPC'];

  function run() public {
    //TODO: Change salt from this test to prod before release
    bytes32 _salt = keccak256(abi.encodePacked('xxxsdsdd23ewXERewewCewew20Factoewewry', msg.sender));
    //TODO: Add old factory address here before deploying
    address _oldFactory = address(0);
    address[] memory factories = new address[](chains.length);

    for (uint256 i; i < chains.length; i++) {
      vm.createSelectFork(vm.rpcUrl(vm.envString(chains[i])));
      bytes memory _bytecode = abi.encodePacked(type(XERC20Factory).creationCode, abi.encode(_oldFactory));

      vm.startBroadcast(deployer);
      address _deployedFactory = getAddress(_bytecode, _salt, CREATE2);

      XERC20Factory fact = new XERC20Factory{salt: _salt}(_oldFactory);
      
      require(address(fact) == _deployedFactory, 'Factory address does not match');

      vm.stopBroadcast();
      console.log(chains[i], 'factory deployed to:', address(_deployedFactory));
      factories[i] = _deployedFactory;
    }

    if (chains.length > 1) {
      for (uint256 i = 1; i < chains.length; i++) {
        vm.assume(factories[i - 1] == factories[i]);
        vm.assume(
          keccak256(factories[i - 1].code) == keccak256(factories[i].code)
        );
      }
    }
  }
}
