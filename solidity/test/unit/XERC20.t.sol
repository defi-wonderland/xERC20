// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {XERC20} from 'contracts/XERC20.sol';
import {IXERC20} from 'interfaces/IXERC20.sol';

abstract contract Base is DSTestFull {
  address internal _owner = _label('_owner');
  address internal _minter = _label('_minter');
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

  function testRemoveMinter(address _randomAddr) public {
    vm.startPrank(_owner);
    _xerc20.setMinter(_randomAddr);
    _xerc20.removeMinter(_randomAddr);
    vm.stopPrank();

    assertEq(_xerc20.minters(_randomAddr), false);
  }

  function testOnlyMinterCanMint(address _randomAddr, uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.assume(_randomAddr != address(0));
    vm.prank(_owner);
    _xerc20.setMinter(_minter);

    vm.prank(_minter);
    _xerc20.mint(_randomAddr, _amount);

    assertEq(_xerc20.balanceOf(_randomAddr), _amount);
  }

  function testOnlyMinterCanBurn(address _randomAddr, uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.assume(_randomAddr != address(0));
    vm.prank(_owner);
    _xerc20.setMinter(_minter);

    vm.startPrank(_minter);
    _xerc20.mint(_randomAddr, _amount);
    _xerc20.burn(_randomAddr, _amount);
    vm.stopPrank();

    assertEq(_xerc20.balanceOf(_randomAddr), 0);
  }

  function testBurnRevertsIfNotMinter(address _randomAddr, uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.expectRevert(IXERC20.OnlyMinters.selector);
    vm.prank(_owner);
    _xerc20.burn(_randomAddr, _amount);
  }

  function testMintRevertsIfNotMinter(address _randomAddr, uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.expectRevert(IXERC20.OnlyMinters.selector);
    vm.prank(_owner);
    _xerc20.mint(_randomAddr, _amount);
  }

  function testRevertsIfNotOwner(address _randomAddr) public {
    vm.expectRevert('Ownable: caller is not the owner');
    _xerc20.setMinter(_randomAddr);
  }
}
