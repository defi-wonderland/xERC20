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
import {IAllowanceTransfer} from 'permit2/src/interfaces/IAllowanceTransfer.sol';
import {IPermit2} from 'permit2/src/interfaces/IPermit2.sol';

abstract contract Base is Test {
  address internal _owner = vm.addr(1);
  uint256 internal _userPrivateKey = 0x1234;
  address internal _user = vm.addr(_userPrivateKey);
  address internal _minter = vm.addr(3);

  XERC20 internal _xerc20 = XERC20(vm.addr(4));
  IERC20 internal _erc20 = IERC20(vm.addr(5));
  IPermit2 internal _permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);

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

  function testDepositWithPermitAllowance(uint256 _amount) public {
    uint48 expiration = uint48(2**48 - 1);

    vm.assume(_amount > 0 && _amount < type(uint160).max);
    vm.deal(_owner, _amount);

    IAllowanceTransfer.PermitSingle memory permit = IAllowanceTransfer.PermitSingle({
      details: IAllowanceTransfer.PermitDetails({
        token: address(_erc20),
        amount: uint160(_amount),
        expiration: expiration,
        nonce: 0
      }),
      spender: address(_lockbox),
      sigDeadline: expiration
    });

    bytes4 permitSelector = bytes4(keccak256("permit(address,((address,uint160,uint48,uint48),address,uint256),bytes)"));
    bytes4 transferFromSelector = bytes4(keccak256(bytes("transferFrom(address,address,uint160,address)")));

    vm.mockCall(
      address(_permit2),
      abi.encodeWithSelector(permitSelector, _owner, permit, bytes("")),
      abi.encode()
    );
    vm.mockCall(
      address(_permit2),
      abi.encodeWithSelector(transferFromSelector, _owner, address(_lockbox), _amount, address(_erc20)),
      abi.encode()
    );
    vm.mockCall(address(_xerc20), abi.encodeWithSelector(IXERC20.mint.selector, _owner, _amount), abi.encode(true));

    vm.expectCall(
      address(_permit2),
      abi.encodeWithSelector(permitSelector, _owner, permit, bytes(""))
    );
    vm.expectCall(
      address(_permit2),
      abi.encodeWithSelector(transferFromSelector, _owner, address(_lockbox), _amount, address(_erc20))
    );
    vm.expectCall(address(_xerc20), abi.encodeCall(XERC20.mint, (_owner, _amount)));

    vm.prank(_owner);
    _lockbox.depositWithPermitAllowance(_amount, _owner, permit, bytes(""));
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

  function testNonNativeIntoNativeDepositReverts(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.deal(_owner, _amount);
    vm.prank(_owner);
    vm.expectRevert(IXERC20Lockbox.IXERC20Lockbox_NotNative.selector);
    _lockbox.deposit{value: _amount}();
  }

  function testNativeRevertsIfDepositIntoNonNative(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.deal(_owner, _amount);
    vm.prank(_owner);
    vm.expectRevert(IXERC20Lockbox.IXERC20Lockbox_Native.selector);
    _nativeLockbox.deposit(_amount);
  }

  function testNativeRevertsIfDepositWithPermitAllowance(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.deal(_owner, _amount);
    vm.prank(_owner);
    vm.expectRevert(IXERC20Lockbox.IXERC20Lockbox_Native.selector);
    
    uint48 expiration = uint48(2**48 - 1);
    IAllowanceTransfer.PermitSingle memory permit = IAllowanceTransfer.PermitSingle({
      details: IAllowanceTransfer.PermitDetails({
        token: address(_erc20),
        amount: uint160(_amount),
        expiration: expiration,
        nonce: 0
      }),
      spender: address(_lockbox),
      sigDeadline: expiration
    }); 

    _nativeLockbox.depositWithPermitAllowance(_amount, _owner, permit, bytes(""));
  }

  function testNativeDeposit(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.deal(_owner, _amount);
    vm.prank(_owner);
    vm.mockCall(address(_xerc20), abi.encodeWithSelector(IXERC20.mint.selector, _owner, _amount), abi.encode(true));

    vm.expectCall(address(_xerc20), abi.encodeCall(XERC20.mint, (_owner, _amount)));
    _nativeLockbox.deposit{value: _amount}();
  }

  function testSendingNativeDepositByTransfer(uint256 _amount) public {
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

  function testNativeWithdraw(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.deal(_owner, _amount);

    vm.startPrank(_owner);
    vm.mockCall(address(_xerc20), abi.encodeWithSelector(IXERC20.mint.selector, _owner, _amount), abi.encode(true));
    _nativeLockbox.deposit{value: _amount}();
    _nativeLockbox.withdraw(_amount);
    vm.stopPrank();

    assertEq(_owner.balance, _amount);
  }
}
