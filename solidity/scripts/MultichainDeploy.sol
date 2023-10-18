// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

// solhint-disable-next-line no-console
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
    address[] memory _factories = new address[](chains.length);

    for (uint256 _i; _i < chains.length; _i++) {
      vm.createSelectFork(vm.rpcUrl(vm.envString(chains[_i])));
      bytes memory _bytecodeFactory = abi.encodePacked(type(XERC20Factory).creationCode);

      vm.startBroadcast(deployer);

      address _deployedFactory = getAddress(_bytecodeFactory, _salt, CREATE2);
      XERC20Factory _fact = new XERC20Factory{salt: _salt}();
      require(address(_fact) == _deployedFactory, 'Factory address does not match');
      
      vm.stopBroadcast();
      // solhint-disable-next-line no-console
      console.log(chains[_i], 'factory deployed to:', address(_deployedFactory));
      _factories[_i] = _deployedFactory;
    }

    if (chains.length > 1) {
      for (uint256 _i = 1; _i < chains.length; _i++) {
        vm.assume(_factories[_i - 1] == _factories[_i]);
        vm.assume(keccak256(_factories[_i - 1].code) == keccak256(_factories[_i].code));
      }
    }
  }
}
