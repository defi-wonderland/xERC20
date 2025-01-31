// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

// solhint-disable-next-line no-console
import {console} from 'forge-std/console.sol';
import {XERC20Factory, IXERC20Factory} from '../contracts/XERC20Factory.sol';
import {Script} from 'forge-std/Script.sol';
import {ScriptingLibrary} from './ScriptingLibrary/ScriptingLibrary.sol';
import { DeploymentConfig, ChainDetails, BridgeDetails} from './XERC20Deploy.sol';
import {stdJson} from 'forge-std/StdJson.sol';

// Deploys a new factory for each chain according to the config
// Only used for initial deployment
contract XERC20FactoryDeployChain is Script, ScriptingLibrary {
  using stdJson for string;
  ////////////////////////// MODIFY ////////////////////////////////
  // When new factories need to be deployed, make sure to update the salt version to avoid address collition
  string public constant SALT = 'xERC20-v1.5';
  //////////////////////////////////////////////////////////////////

  uint256 public deployerPk = vm.envUint('DEPLOYER_PRIVATE_KEY');

  function run() public {
    bytes32 _salt = keccak256(abi.encodePacked(SALT, msg.sender));

    string memory _json = vm.readFile('./solidity/scripts/xerc20-deployment-config.json');
    DeploymentConfig memory _data = abi.decode(_json.parseRaw('.'), (DeploymentConfig));
    uint256 _chainAmount = _data.chainDetails.length;

    for (uint256 i; i < _chainAmount; i++) {
      ChainDetails memory _chainDetails = _data.chainDetails[i];
      vm.createSelectFork(vm.rpcUrl(vm.envString(_chainDetails.rpcEnvName)));
      vm.startBroadcast(deployerPk);
      XERC20Factory _factory = new XERC20Factory{salt: _salt}();
      vm.stopBroadcast();

      // solhint-disable-next-line no-console
      console.log('Factory deployed to:', address(_factory));
    }
    
  }
}
