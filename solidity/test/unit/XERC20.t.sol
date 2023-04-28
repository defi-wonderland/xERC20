// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {XERC20} from 'contracts/XERC20.sol';

abstract contract Base is DSTestFull {
  address internal _owner = _label('_owner');
  XERC20 internal _xerc20;

  function setUp() public virtual {
    vm.prank(_owner);
    _xerc20 = new XERC20('Test', 'TST');
  }
}

contract UnitNames is Base {
  function testName() public {
    assertEq('xTest', _xerc20.name());
  }

  function testSymbol() public {
    assertEq('xTST', _xerc20.symbol());
  }
}

contract UnitMinters is Base {
  function testSetMinter(address _randomAddr) public {
    vm.prank(_owner);
    _xerc20.setMinter(_randomAddr);
    assertEq(_xerc20.minters(_randomAddr), true);
  }

  function testRevertsIfNotOwner(address _randomAddr) public {
    vm.expectRevert('Ownable: caller is not the owner');
    _xerc20.setMinter(_randomAddr);
  }
}
