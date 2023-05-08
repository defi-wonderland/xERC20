// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {console} from 'forge-std/console.sol';
import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';

import {XERC20Factory, IXERC20Factory} from 'contracts/XERC20Factory.sol';

contract CommonE2EBase is DSTestFull {
  uint256 internal constant _FORK_BLOCK = 1_721_668;
  address internal _user = _label('user');
  address internal _owner = _label('owner');

  XERC20Factory internal _xerc20Factory;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), _FORK_BLOCK);

    vm.startPrank(_owner);
    _xerc20Factory = new XERC20Factory();
    vm.stopPrank();
  }
}
