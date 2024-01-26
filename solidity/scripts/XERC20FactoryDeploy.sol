// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

// solhint-disable-next-line no-console
import {console} from 'forge-std/console.sol';
import {XERC20Factory, IXERC20Factory} from '../contracts/XERC20Factory.sol';
import {Script} from 'forge-std/Script.sol';
import {ScriptingLibrary} from './ScriptingLibrary/ScriptingLibrary.sol';

contract XERC20FactoryDeploy is Script, ScriptingLibrary {
  ////////////////////////// MODIFY ////////////////////////////////
  // When new factories need to be deployed, make sure to update the salt version to avoid address collition
  string public constant SALT = 'xERC20-v1.5';
  //////////////////////////////////////////////////////////////////

  uint256 public deployerPk = vm.envUint('DEPLOYER_PRIVATE_KEY');

  function run() public {
    bytes32 _salt = keccak256(abi.encodePacked(SALT, msg.sender));

    vm.startBroadcast(deployerPk);
    XERC20Factory _factory = new XERC20Factory{salt: _salt}();
    vm.stopBroadcast();

    // solhint-disable-next-line no-console
    console.log('Factory deployed to:', address(_factory));
  }
}
