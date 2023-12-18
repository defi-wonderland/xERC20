// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {XERC20} from '../../contracts/XERC20.sol';
import {XERC20Lockbox} from '../../contracts/XERC20Lockbox.sol';
import {IXERC20Lockbox} from '../../interfaces/IXERC20Lockbox.sol';
import {IXERC20} from '../../interfaces/IXERC20.sol';

abstract contract Base is Test {
  address internal _owner = vm.addr(1);
  uint256 internal _userPrivateKey = 0x1234;
  address internal _user = vm.addr(_userPrivateKey);
  address internal _minter = vm.addr(3);

  XERC20 internal _xerc20 = XERC20(vm.addr(4));
  IERC20 internal _erc20 = IERC20(vm.addr(5));

  event Deposit(address _sender, uint256 _amount);
  event Withdraw(address _sender, uint256 _amount);

  XERC20Lockbox internal _lockbox;
  XERC20Lockbox internal _nativeLockbox;

  function setUp() public virtual {
    vm.startPrank(_owner);
    _nativeLockbox = new XERC20Lockbox(address(_xerc20), address(_erc20), true);
    _lockbox = new XERC20Lockbox(address(_xerc20), address(_erc20), false);
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

  function testDepositTo(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.mockCall(
      address(_erc20),
      abi.encodeWithSelector(IERC20.transferFrom.selector, _owner, address(_lockbox), _amount),
      abi.encode(true)
    );
    vm.mockCall(address(_xerc20), abi.encodeWithSelector(IXERC20.mint.selector, _user, _amount), abi.encode(true));

    vm.expectCall(address(_xerc20), abi.encodeCall(XERC20.mint, (_user, _amount)));
    vm.expectCall(address(_erc20), abi.encodeCall(ERC20.transferFrom, (_owner, address(_lockbox), _amount)));

    vm.prank(_owner);
    _lockbox.depositTo(_user, _amount);
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
    emit Deposit(_owner, _amount);
    vm.prank(_owner);
    _lockbox.deposit(_amount);
  }

  function testNonGasTokenIntoGasTokenDepositReverts(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.deal(_owner, _amount);
    vm.prank(_owner);
    vm.expectRevert(IXERC20Lockbox.IXERC20Lockbox_NotGasToken.selector);
    _lockbox.depositGasToken{value: _amount}();
  }

  function testNonGasTokenIntoGasTokenDeposittoReverts(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.deal(_owner, _amount);
    vm.prank(_owner);
    vm.expectRevert(IXERC20Lockbox.IXERC20Lockbox_NotGasToken.selector);
    _lockbox.depositGasTokenTo{value: _amount}(_user);
  }

  function testGasTokenRevertsIfDepositIntoNonGasToken(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.deal(_owner, _amount);
    vm.prank(_owner);
    vm.expectRevert(IXERC20Lockbox.IXERC20Lockbox_GasToken.selector);
    _nativeLockbox.deposit(_amount);
  }

  function testGasTokenRevertsIfDepositToIntoNonGasToken(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.deal(_owner, _amount);
    vm.prank(_owner);
    vm.expectRevert(IXERC20Lockbox.IXERC20Lockbox_GasToken.selector);
    _nativeLockbox.depositTo(_user, _amount);
  }

  function testGasTokenDeposit(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.deal(_owner, _amount);
    vm.prank(_owner);
    vm.mockCall(address(_xerc20), abi.encodeWithSelector(IXERC20.mint.selector, _owner, _amount), abi.encode(true));

    vm.expectCall(address(_xerc20), abi.encodeCall(XERC20.mint, (_owner, _amount)));
    _nativeLockbox.depositGasToken{value: _amount}();
  }

  function testGasTokenDepositTo(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.deal(_owner, _amount);
    vm.prank(_owner);
    vm.mockCall(address(_xerc20), abi.encodeWithSelector(IXERC20.mint.selector, _user, _amount), abi.encode(true));

    vm.expectCall(address(_xerc20), abi.encodeCall(XERC20.mint, (_user, _amount)));
    _nativeLockbox.depositGasTokenTo{value: _amount}(_user);
  }

  function testSendingGasTokenDepositByTransfer(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.deal(_owner, _amount);
    vm.mockCall(address(_xerc20), abi.encodeWithSelector(IXERC20.mint.selector, _owner, _amount), abi.encode(true));

    vm.expectCall(address(_xerc20), abi.encodeCall(XERC20.mint, (_owner, _amount)));
    vm.prank(_owner);
    (bool _success,) = address(_nativeLockbox).call{value: _amount}('');
    assertEq(_success, true);
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
    emit Withdraw(_owner, _amount);
    vm.prank(_owner);
    _lockbox.withdraw(_amount);
  }

  function testGasTokenWithdraw(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.deal(_owner, _amount);

    vm.startPrank(_owner);
    vm.mockCall(address(_xerc20), abi.encodeWithSelector(IXERC20.mint.selector, _owner, _amount), abi.encode(true));
    _nativeLockbox.depositGasToken{value: _amount}();
    _nativeLockbox.withdraw(_amount);
    vm.stopPrank();

    assertEq(_owner.balance, _amount);
  }

  function testGasTokenWithdrawTo(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.deal(_owner, _amount);

    vm.startPrank(_owner);
    vm.mockCall(address(_xerc20), abi.encodeWithSelector(IXERC20.mint.selector, _owner, _amount), abi.encode(true));
    _nativeLockbox.depositGasToken{value: _amount}();
    _nativeLockbox.withdrawTo(_user, _amount);
    vm.stopPrank();

    assertEq(_user.balance, _amount);
  }
}
