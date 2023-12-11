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
  string[] public chains = [
    'ETHEREUM_MAINNET_RPC',
    'POLYGON_MAINNET_RPC',
    'OPTIMISM_MAINNET_RPC',
    'ARBITRUM_MAINNET_RPC',
    'GNOSIS_RPC',
    'BSC_RPC',
    'ETHEREUM_GOERLI_RPC',
    'POLYGON_MUMBAI_RPC',
    'ARBITRUM_GOERLI_RPC',
    'OPTIMISM_GOERLI_RPC'
  ];

  function run() public {
    // When new factories need to be deployed, make sure to update the salt version
    bytes32 _salt = keccak256(abi.encodePacked('xERC20-v1.2', msg.sender));
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
