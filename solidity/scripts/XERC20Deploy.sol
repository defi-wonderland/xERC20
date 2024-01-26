// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

// solhint-disable-next-line no-console
import {console} from 'forge-std/console.sol';
import {Test} from 'forge-std/Test.sol';
import {Script} from 'forge-std/Script.sol';
import {stdJson} from 'forge-std/StdJson.sol';
import {XERC20} from '../contracts/XERC20.sol';
import {XERC20Lockbox} from '../contracts/XERC20Lockbox.sol';
import {XERC20Factory, IXERC20Factory} from '../contracts/XERC20Factory.sol';
import {ScriptingLibrary} from './ScriptingLibrary/ScriptingLibrary.sol';

// NOTE: IMPORTANT! Struct members should be order by ALPHABETICAL order. DO NOT modify them.
// Please read https://book.getfoundry.sh/cheatcodes/parse-json to understand the
// limitations and caveats of the JSON parsing cheats.
struct BridgeDetails {
  address bridge; // The address of the bridge
  uint256 burnLimit; // The 24hs burn limit of the bridge
  uint256 mintLimit; // The 24hs mint limit of the bridge
}

struct ChainDetails {
  BridgeDetails[] bridgeDetails; // The array of bridges to configure for this chain
  address erc20; // The address of the ERC20 canonical token of that chain (address(0) if none)
  address governor; // The governor address of the xERC20
  bool isNativeGasToken; // Whether or not the token is the native gas token of the chain. E.g. Are you deploying an xERC20 for MATIC in Polygon?
  string rpcEnvName; // The name of the RPC to use from the .env file
}

struct DeploymentConfig {
  ChainDetails[] chainDetails;
  string name; // The name to use for the xERC20
  string symbol; // The symbol to use for the xERC20
}

contract XERC20Deploy is Script, ScriptingLibrary {
  using stdJson for string;

  uint256 public deployer = vm.envUint('DEPLOYER_PRIVATE_KEY');
  XERC20Factory public factory = XERC20Factory(0xb913bE186110B1119d5B9582F316f142c908fc25);

  function run() public {
    string memory _json = vm.readFile('./solidity/scripts/xerc20-deployment-config.json');
    DeploymentConfig memory _data = abi.decode(_json.parseRaw('.'), (DeploymentConfig));
    uint256 _chainAmount = _data.chainDetails.length;
    address[] memory _tokens = new address[](_chainAmount);

    for (uint256 i; i < _chainAmount; i++) {
      ChainDetails memory _chainDetails = _data.chainDetails[i];

      vm.createSelectFork(vm.rpcUrl(vm.envString(_chainDetails.rpcEnvName)));
      vm.startBroadcast(deployer);
      // If this chain does not have a factory we will revert
      require(
        keccak256(address(factory).code) != keccak256(address(0).code), 'There is no factory deployed on this chain'
      );

      BridgeDetails[] memory _bridgeDetails = _chainDetails.bridgeDetails;

      // flatten all bridge details
      address[] memory _bridges = new address[](_bridgeDetails.length);
      uint256[] memory _burnLimits = new uint256[](_bridgeDetails.length);
      uint256[] memory _mintLimits = new uint256[](_bridgeDetails.length);
      for (uint256 _bridgeIndex; _bridgeIndex < _bridgeDetails.length; _bridgeIndex++) {
        _bridges[_bridgeIndex] = _bridgeDetails[_bridgeIndex].bridge;
        _burnLimits[_bridgeIndex] = _bridgeDetails[_bridgeIndex].burnLimit;
        _mintLimits[_bridgeIndex] = _bridgeDetails[_bridgeIndex].mintLimit;
      }

      // deploy xerc20
      address _xerc20 = factory.deployXERC20(_data.name, _data.symbol, _mintLimits, _burnLimits, _bridges);

      // deploy lockbox if needed
      address _lockbox;
      if (_chainDetails.erc20 != address(0) && !_chainDetails.isNativeGasToken) {
        _lockbox = factory.deployLockbox(_xerc20, _chainDetails.erc20, _chainDetails.isNativeGasToken);
      }

      // transfer xerc20 ownership to the governor
      XERC20(_xerc20).transferOwnership(_chainDetails.governor);

      vm.stopBroadcast();

      // solhint-disable-next-line no-console
      console.log('Deployment to chain with RPC name: ', _chainDetails.rpcEnvName);
      // solhint-disable-next-line no-console
      console.log('xERC20 token deployed: ', _xerc20);
      if (_lockbox != address(0)) {
        // solhint-disable-next-line no-console
        console.log('Lockbox deployed: ', _lockbox);
      }
      _tokens[i] = _xerc20;
    }

    if (_chainAmount > 1) {
      for (uint256 i = 1; i < _chainAmount; i++) {
        vm.assume(_tokens[i - 1] == _tokens[i]);
        vm.assume(keccak256(_tokens[i - 1].code) == keccak256(_tokens[i].code));
      }
    }
  }
}
