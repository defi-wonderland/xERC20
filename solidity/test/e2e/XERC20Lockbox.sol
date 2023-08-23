// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {CommonE2EBase} from './Common.sol';
import {PermitHash} from 'permit2/src/libraries/PermitHash.sol';
import {IAllowanceTransfer} from 'permit2/src/interfaces/IAllowanceTransfer.sol';
import {PermitSignature} from 'permit2/test/utils/PermitSignature.sol';
import {IEIP712} from 'permit2/src/interfaces/IEIP712.sol';
import {XERC20Lockbox} from 'contracts/XERC20Lockbox.sol';
import {XERC20} from 'contracts/XERC20.sol';
import {console} from 'forge-std/console.sol';

contract E2ELockbox is CommonE2EBase, PermitSignature {
  function testLockbox() public {
    assertEq(address(_lockbox.XERC20()), address(_xerc20));
    assertEq(address(_lockbox.ERC20()), address(_dai));
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

  function testDepositWithPermitAllowance() public {
    address _permit2 = address(_lockbox.PERMIT2());
    bytes32 _domainSeparator = IEIP712(_permit2).DOMAIN_SEPARATOR();
    uint256 _amount = 100 ether;
    uint48 _expiration = uint48(2**48 - 1);

    deal(address(_dai), _user, _amount);
    vm.startPrank(_user);
    _dai.approve(_permit2, _amount);
    vm.stopPrank();

    IAllowanceTransfer.PermitSingle memory permit = IAllowanceTransfer.PermitSingle({
      details: IAllowanceTransfer.PermitDetails({
        token: address(_dai),
        amount: uint160(_amount),
        expiration: _expiration,
        nonce: 0
      }),
      spender: address(_lockbox),
      sigDeadline: _expiration
    });

    bytes memory signature = getPermitSignature(permit, _userPrivateKey, _domainSeparator);

    vm.startPrank(_multicall);
    _lockbox.depositWithPermitAllowance(_amount, _user, permit, signature);
    vm.stopPrank();

    assertEq(XERC20(_xerc20).balanceOf(_user), _amount);
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
