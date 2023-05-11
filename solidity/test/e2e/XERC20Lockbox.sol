// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {CommonE2EBase} from './Common.sol';
import {XERC20Lockbox} from 'contracts/XERC20Lockbox.sol';
import {XERC20} from 'contracts/XERC20.sol';

contract E2ELockbox is CommonE2EBase {
  function testLockbox() public {
    assertEq(address(_lockbox.xerc20()), address(_xerc20));
    assertEq(address(_lockbox.erc20()), address(_dai));
  }

  function testDeposit() public {
    deal(address(_dai), _user, 100 ether);
    vm.startPrank(_user);
    _dai.approve(address(_lockbox), 100 ether);
    _lockbox.deposit(100 ether);
    vm.stopPrank();

    assertEq(XERC20(_xerc20).balanceOf(_user), 100 ether);
    assertEq(_dai.balanceOf(_user), 0 ether);
  }

  function testWithdraw() public {
    deal(address(_dai), _user, 100 ether);
    vm.startPrank(_user);
    _dai.approve(address(_lockbox), 100 ether);
    _lockbox.deposit(100 ether);
    vm.stopPrank();

    vm.startPrank(_user);
    _lockbox.withdraw(100 ether);
    vm.stopPrank();

    assertEq(XERC20(_xerc20).balanceOf(_user), 0 ether);
    assertEq(_dai.balanceOf(_user), 100 ether);
  }
}
