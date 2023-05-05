// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {XERC20} from 'contracts/XERC20.sol';
import {XERC20Lockbox} from 'contracts/XERC20Lockbox.sol';
import {IXERC20Lockbox} from 'interfaces/IXERC20Lockbox.sol';
import {IXERC20} from 'interfaces/IXERC20.sol';

abstract contract Base is DSTestFull {
  address internal _owner = vm.addr(1);
  address internal _user = vm.addr(2);
  address internal _minter = vm.addr(3);

  XERC20 internal _xerc20 = XERC20(vm.addr(4));
  IERC20 internal _erc20 = IERC20(vm.addr(5));

  event DepositedERC20(address _sender, uint256 _amount);
  event WithdrawnERC20(address _sender, uint256 _amount);

  XERC20Lockbox internal _lockbox;

  function setUp() public virtual {
    vm.startPrank(_owner);
    _lockbox = new XERC20Lockbox(address(_xerc20), address(_erc20));
    vm.stopPrank();
  }
}

contract UnitDeposit is Base {
  function testDeposit(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.mockCall(
      address(_erc20),
      abi.encodeWithSelector(IERC20.transferFrom.selector, _owner, address(_lockbox), _amount),
      abi.encode(true)
    );
    vm.mockCall(address(_xerc20), abi.encodeWithSelector(IXERC20.mint.selector, _owner, _amount), abi.encode(true));

    vm.expectCall(address(_xerc20), abi.encodeCall(XERC20.mint, (_owner, _amount)));
    vm.expectCall(address(_erc20), abi.encodeCall(ERC20.transferFrom, (_owner, address(_lockbox), _amount)));

    vm.prank(_owner);
    _lockbox.deposit(_amount);
  }

  function testDepositEmitsEvent(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.mockCall(
      address(_erc20),
      abi.encodeWithSelector(IERC20.transferFrom.selector, _owner, address(_lockbox), _amount),
      abi.encode(true)
    );
    vm.mockCall(address(_xerc20), abi.encodeWithSelector(IXERC20.mint.selector, _owner, _amount), abi.encode(true));

    vm.expectEmit(true, true, true, true);
    emit DepositedERC20(_owner, _amount);
    vm.prank(_owner);
    _lockbox.deposit(_amount);
  }
}

contract UnitWithdraw is Base {
  function testWithdraw(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.mockCall(address(_xerc20), abi.encodeWithSelector(IXERC20.burn.selector, _owner, _amount), abi.encode(true));
    vm.mockCall(address(_erc20), abi.encodeWithSelector(IERC20.transfer.selector, _owner, _amount), abi.encode(true));

    vm.expectCall(address(_xerc20), abi.encodeCall(XERC20.burn, (_owner, _amount)));
    vm.expectCall(address(_erc20), abi.encodeCall(ERC20.transfer, (_owner, _amount)));
    vm.prank(_owner);
    _lockbox.withdraw(_amount);
  }

  function testWithdrawEmitsEvent(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.mockCall(address(_xerc20), abi.encodeWithSelector(IXERC20.burn.selector, _owner, _amount), abi.encode(true));
    vm.mockCall(address(_erc20), abi.encodeWithSelector(IERC20.transfer.selector, _owner, _amount), abi.encode(true));

    vm.expectEmit(true, true, true, true);
    emit WithdrawnERC20(_owner, _amount);
    vm.prank(_owner);
    _lockbox.withdraw(_amount);
  }
}
