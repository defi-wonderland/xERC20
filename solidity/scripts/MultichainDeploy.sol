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
  function run() external {
    vm.startBroadcast();

    vm.createSelectFork(vm.rpcUrl('mainnet'));
    address _mainnetFactory = address(new XERC20Factory());
    console.log('ETH Mainnet Factory deployed to: ', _mainnetFactory);
    vm.stopBroadcast();
  }
}
