import {IbcMwUser} from '@open-ibc/vibc-core-smart-contracts/contracts/interfaces/IbcMiddleware.sol';
import '../contracts/PolyERC20.sol';
import './XERC20Deploy.sol';
import '../contracts/PolyERC20Factory.sol';

contract PolyERC20Deploy is Script {
  using stdJson for string;
@@ -15,7 +16,7 @@ contract PolyERC20Deploy is Script {
    return keccak256(bytes(vm.envString('SALT')));
  }

  function run() external {
  function deployPolyERC20() public {
    string memory _json = vm.readFile('./solidity/scripts/xerc20-deployment-config.json');
    DeploymentConfig memory _data = abi.decode(_json.parseRaw('.'), (DeploymentConfig));

@@ -47,4 +48,51 @@ contract PolyERC20Deploy is Script {

    vm.stopBroadcast();
  }

  function deployPolyERC20WithFactory() public {
    string memory _json = vm.readFile('./solidity/scripts/xerc20-deployment-config.json');
    DeploymentConfig memory _data = abi.decode(_json.parseRaw('.'), (DeploymentConfig));

    uint256 baseFork = vm.createFork(vm.rpcUrl(vm.envString('BASE_SEPOLIA_RPC')));
    uint256 opFork = vm.createFork(vm.rpcUrl(vm.envString('OPTIMISM_SEPOLIA_RPC')));
    uint256 chainId = vm.envUint('CHAIN_ID');

    if (chainId == 84_532) {
      string[] memory channels = new string[](1);
      channels[0] = 'channel-11';

      vm.selectFork(baseFork);
      vm.startBroadcast(deployer);
      IbcMwUser baseMW = IbcMwUser(payable(vm.envAddress('BASE_UC_MW_SIM')));
      PolyERC20Factory factory = new PolyERC20Factory{salt: salt()}();
      factory.setDefaultMw(address(baseMW));
      PolyERC20FixedSupply basePolyToken =
        factory.deployXPolyERC20(channels, _data.name, _data.symbol, salt(), 1_000_000_000);

      // solhint-disable-next-line no-console
      console.log('factory deployed on Base chain at:', address(factory));
      // solhint-disable-next-line no-console
      console.log('PolyERC20 token deployed on Base chain at:', address(basePolyToken));
    }

    if (chainId == 11_155_420) {
      string[] memory channels = new string[](1);
      channels[0] = 'channel-10';

      vm.selectFork(opFork);
      vm.startBroadcast(deployer);
      IbcMwUser opMW = IbcMwUser(payable(vm.envAddress('OP_UC_MW_SIM')));
      PolyERC20Factory factory = new PolyERC20Factory{salt: salt()}();
      factory.setDefaultMw(address(opMW));

      // solhint-disable-next-line no-console
      console.log('factory deployed on Optimism chain at:', address(factory));
    }

    vm.stopBroadcast();
  }

  function run() external {
    deployPolyERC20();
  }
}
