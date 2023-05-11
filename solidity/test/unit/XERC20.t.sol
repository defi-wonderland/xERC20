// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {XERC20} from 'contracts/XERC20.sol';
import {IXERC20Factory} from 'interfaces/IXERC20Factory.sol';
import {IXERC20} from 'interfaces/IXERC20.sol';

abstract contract Base is Test {
  address internal _owner = vm.addr(1);
  address internal _user = vm.addr(2);
  address internal _minter = vm.addr(3);

  XERC20 internal _xerc20;

  event MinterLimitsCreated(uint256[] _limits, address[] _minters);
  event MinterLimitsChanged(uint256 _oldLimit, uint256 _newLimit, address _minter);
  event BurnerLimitsCreated(uint256[] _limits, address[] _burners);
  event BurnerLimitsChanged(uint256 _oldLimit, uint256 _newLimit, address _burner);

  function setUp() public virtual {
    vm.startPrank(_owner);
    _xerc20 = new XERC20('Test', 'TST', _owner);
    vm.stopPrank();
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

contract UnitMintBurn is Base {
  function testMintRevertsIfNotApprove(uint256 _amount) public {
    vm.assume(_amount > 0);
    vm.prank(_user);
    vm.expectRevert(IXERC20.IXERC20_NotHighEnoughLimits.selector);
    _xerc20.mint(_user, _amount);
  }

  function testBurnRevertsWhenLimitIsTooLow(uint256 _amount0, uint256 _amount1) public {
    _amount0 = bound(_amount0, 1, 1e40);
    _amount1 = bound(_amount1, 1, 1e40);
    vm.assume(_amount1 > _amount0);
    vm.prank(_owner);
    _xerc20.changeMinterLimit(_amount0, _user);

    vm.startPrank(_user);
    _xerc20.mint(_user, _amount0);
    vm.expectRevert(IXERC20.IXERC20_NotHighEnoughLimits.selector);
    _xerc20.burn(_user, _amount1);
    vm.stopPrank();
  }

  function testMint(uint256 _amount) public {
    vm.assume(_amount > 0);

    vm.prank(_owner);
    _xerc20.changeMinterLimit(_amount, _user);
    vm.prank(_user);
    _xerc20.mint(_minter, _amount);

    assertEq(_xerc20.balanceOf(_minter), _amount);
  }

  function testBurn(uint256 _amount) public {
    _amount = bound(_amount, 1, 1e40);
    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_amount, _user);
    _xerc20.changeBurnerLimit(_amount, _user);
    vm.stopPrank();

    vm.startPrank(_user);
    _xerc20.mint(_user, _amount);
    _xerc20.burn(_user, _amount);
    vm.stopPrank();

    assertEq(_xerc20.balanceOf(_user), 0);
  }

  function testMintByTransfer(uint256 _amount, address _randomAddr) public {
    vm.assume(_amount > 0);
    vm.assume(_randomAddr != address(0));

    vm.prank(_owner);
    _xerc20.changeMinterLimit(_amount, _user);

    vm.prank(_user);
    _xerc20.transfer(_randomAddr, _amount);

    assertEq(_xerc20.balanceOf(_randomAddr), _amount);
  }

  function testBurnByTransfer(uint256 _amount, address _randomAddr) public {
    vm.assume(_amount > 0);
    vm.assume(_randomAddr != address(0));

    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_amount, _user);
    _xerc20.changeBurnerLimit(_amount, _user);
    vm.stopPrank();

    vm.prank(_user);
    _xerc20.transfer(_randomAddr, _amount);

    vm.prank(_randomAddr);
    _xerc20.transfer(_user, _amount);

    assertEq(_xerc20.totalSupply(), 0);
  }

  function testNormalTransferStillWorks(uint256 _amount, address _randomAddr) public {
    vm.assume(_amount > 0);
    vm.assume(_randomAddr != address(0));

    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_amount, _minter);
    vm.stopPrank();

    vm.prank(_minter);
    _xerc20.mint(_user, _amount);

    vm.prank(_user);
    bool _success = _xerc20.transfer(_randomAddr, _amount);

    assertEq(_success, true);
    assertEq(_xerc20.balanceOf(_randomAddr), _amount);
  }

  function testTransferFromRevertsWithNoAllowance(uint256 _amount) public {
    vm.assume(_amount > 0);

    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_amount, _minter);
    _xerc20.changeBurnerLimit(_amount, _minter);
    vm.stopPrank();

    vm.prank(_minter);
    vm.expectRevert('ERC20: insufficient allowance');
    _xerc20.transferFrom(_owner, _minter, _amount);

    vm.prank(_minter);
    vm.expectRevert('ERC20: insufficient allowance');
    _xerc20.transferFrom(_minter, _owner, _amount);
  }

  function testTransferFromCanMint(uint256 _amount) public {
    vm.assume(_amount > 0);

    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_amount, _minter);
    vm.stopPrank();

    vm.prank(_minter);
    _xerc20.approve(_minter, _amount);

    vm.prank(_minter);
    _xerc20.transferFrom(_minter, _user, _amount);

    assertEq(_xerc20.balanceOf(_user), _amount);
  }

  function testTransferFromCanMintFromDifferentAddr(uint256 _amount) public {
    vm.assume(_amount > 0);

    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_amount, _minter);
    vm.stopPrank();

    vm.prank(_minter);
    _xerc20.approve(_user, _amount);

    vm.prank(_user);
    _xerc20.transferFrom(_minter, _owner, _amount);

    assertEq(_xerc20.balanceOf(_owner), _amount);
  }

  function testTransferFromCanBurn(uint256 _amount) public {
    vm.assume(_amount > 0);

    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_amount, _minter);
    _xerc20.changeBurnerLimit(_amount, _minter);
    vm.stopPrank();

    vm.startPrank(_minter);
    _xerc20.mint(_user, _amount);
    vm.stopPrank();

    vm.prank(_user);
    _xerc20.approve(_minter, _amount);

    vm.prank(_minter);
    _xerc20.transferFrom(_user, _minter, _amount);

    assertEq(_xerc20.totalSupply(), 0);
  }

  function testTransferShouldRevertIfLimitIsNotEnough(uint256 _amount) public {
    _amount = bound(_amount, 1, 1e40);

    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_amount, _minter);
    _xerc20.changeBurnerLimit(_amount, _minter);

    _xerc20.changeMinterLimit(_amount + 1, _owner);
    _xerc20.mint(_user, _amount + 1);
    vm.stopPrank();

    vm.prank(_minter);
    vm.expectRevert(IXERC20.IXERC20_NotHighEnoughLimits.selector);
    _xerc20.transfer(_user, _amount + 1);

    vm.prank(_user);
    vm.expectRevert(IXERC20.IXERC20_NotHighEnoughLimits.selector);
    _xerc20.transfer(_minter, _amount + 1);
  }

  function testTransferFromShouldRevertIfLimitIsNotEnough(uint256 _amount) public {
    _amount = bound(_amount, 1, 1e40);

    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_amount, _minter);
    _xerc20.changeBurnerLimit(_amount, _minter);

    _xerc20.changeMinterLimit(_amount + 1, _owner);
    _xerc20.mint(_user, _amount + 1);
    vm.stopPrank();

    vm.prank(_minter);
    _xerc20.approve(_minter, _amount + 1);

    vm.prank(_user);
    _xerc20.approve(_minter, _amount + 1);

    vm.prank(_minter);
    vm.expectRevert(IXERC20.IXERC20_NotHighEnoughLimits.selector);
    _xerc20.transferFrom(_user, _minter, _amount + 1);

    vm.prank(_minter);
    vm.expectRevert(IXERC20.IXERC20_NotHighEnoughLimits.selector);
    _xerc20.transferFrom(_minter, _user, _amount + 1);
  }

  function testTransferToBurnerFromMinter(uint256 _amount) public {
    vm.assume(_amount > 0);

    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_amount, _minter);
    _xerc20.changeBurnerLimit(_amount, _user);

    vm.stopPrank();

    vm.prank(_minter);
    _xerc20.transfer(_user, _amount);

    assertEq(_xerc20.totalSupply(), 0);
    assertEq(_xerc20.getMinterCurrentLimit(_minter), 0);
    assertEq(_xerc20.getBurnerCurrentLimit(_user), 0);
  }

  function testTransferFromToBurnerFromMinter(uint256 _amount) public {
    vm.assume(_amount > 0);

    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_amount, _minter);
    _xerc20.changeBurnerLimit(_amount, _user);
    vm.stopPrank();

    vm.startPrank(_minter);
    _xerc20.approve(_minter, _amount);
    _xerc20.transferFrom(_minter, _user, _amount);
    vm.stopPrank();

    assertEq(_xerc20.totalSupply(), 0);
    assertEq(_xerc20.getMinterCurrentLimit(_minter), 0);
    assertEq(_xerc20.getBurnerCurrentLimit(_user), 0);
  }

  function testTransferWhenBothHavePermissions(uint256 _amount) public {
    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_amount, _minter);
    _xerc20.changeMinterLimit(_amount, _user);
    _xerc20.changeBurnerLimit(_amount, _minter);
    _xerc20.changeBurnerLimit(_amount, _user);

    vm.stopPrank();

    vm.prank(_user);
    _xerc20.transfer(_minter, _amount);

    assertEq(_xerc20.totalSupply(), 0);
    assertEq(_xerc20.getMinterCurrentLimit(_user), 0);
    assertEq(_xerc20.getBurnerCurrentLimit(_minter), 0);
  }
}

contract UnitCreateParams is Base {
  function testChangeLimit(uint256 _amount, address _randomAddr) public {
    vm.assume(_randomAddr != address(0));
    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_amount, _randomAddr);
    _xerc20.changeBurnerLimit(_amount, _randomAddr);
    vm.stopPrank();
    assertEq(_xerc20.getMinterMaxLimit(_randomAddr), _amount);
    assertEq(_xerc20.getBurnerMaxLimit(_randomAddr), _amount);
  }

  function testRevertsWithWrongCaller() public {
    vm.expectRevert('Ownable: caller is not the owner');
    _xerc20.changeMinterLimit(1e18, _minter);
  }

  function testAddingMintersAndLimits(
    uint256 _amount0,
    uint256 _amount1,
    uint256 _amount2,
    address _user0,
    address _user1,
    address _user2
  ) public {
    vm.assume(_amount0 > 0);
    vm.assume(_amount1 > 0);
    vm.assume(_amount2 > 0);

    vm.assume(_user0 != _user1 && _user1 != _user2 && _user0 != _user2);
    uint256[] memory _limits = new uint256[](3);
    address[] memory _minters = new address[](3);

    _limits[0] = _amount0;
    _limits[1] = _amount1;
    _limits[2] = _amount2;

    _minters[0] = _user0;
    _minters[1] = _user1;
    _minters[2] = _user2;

    vm.startPrank(_owner);
    _xerc20.createMinterLimits(_limits, _minters);
    _xerc20.createBurnerLimits(_limits, _minters);
    vm.stopPrank();

    assertEq(_xerc20.getMinterMaxLimit(_user0), _amount0);
    assertEq(_xerc20.getMinterMaxLimit(_user1), _amount1);
    assertEq(_xerc20.getMinterMaxLimit(_user2), _amount2);
    assertEq(_xerc20.getBurnerMaxLimit(_user0), _amount0);
    assertEq(_xerc20.getBurnerMaxLimit(_user1), _amount1);
    assertEq(_xerc20.getBurnerMaxLimit(_user2), _amount2);
  }

  function testCreateMinterLimitsEmitsEvent() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.expectEmit(true, true, true, true);
    emit MinterLimitsCreated(_limits, _minters);
    vm.prank(_owner);
    _xerc20.createMinterLimits(_limits, _minters);
  }

  function testCreateBurnerLimitsEmitsEvent() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.expectEmit(true, true, true, true);
    emit BurnerLimitsCreated(_limits, _minters);
    vm.prank(_owner);
    _xerc20.createBurnerLimits(_limits, _minters);
  }

  function testChangeMinterLimitEmitsEvent(uint256 _limit, address _minter) public {
    vm.prank(_owner);
    vm.expectEmit(true, true, true, true);
    emit MinterLimitsChanged(0, _limit, _minter);
    _xerc20.changeMinterLimit(_limit, _minter);
  }

  function testChangeBurnerLimitEmitsEvent(uint256 _limit, address _minter) public {
    vm.prank(_owner);
    vm.expectEmit(true, true, true, true);
    emit BurnerLimitsChanged(0, _limit, _minter);
    _xerc20.changeBurnerLimit(_limit, _minter);
  }

  function testSettingLimitsToUnapprovedUser(uint256 _amount) public {
    vm.assume(_amount > 0);

    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_amount, _minter);
    _xerc20.changeBurnerLimit(_amount, _minter);
    vm.stopPrank();

    assertEq(_xerc20.getMinterMaxLimit(_minter), _amount);
    assertEq(_xerc20.getBurnerMaxLimit(_minter), _amount);
  }

  function testUseLimitsUpdatesLimit(uint256 _limit, address _minter) public {
    vm.assume(_limit > 1e6);
    vm.assume(_minter != address(0));
    vm.warp(1_683_145_698); // current timestamp at the time of testing

    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_limit, _minter);
    _xerc20.changeBurnerLimit(_limit, _minter);
    vm.stopPrank();

    vm.startPrank(_minter);
    _xerc20.mint(_minter, _limit);
    _xerc20.burn(_minter, _limit);
    vm.stopPrank();

    assertEq(_xerc20.getMinterMaxLimit(_minter), _limit);
    assertEq(_xerc20.getMinterCurrentLimit(_minter), 0);
    assertEq(_xerc20.getBurnerMaxLimit(_minter), _limit);
    assertEq(_xerc20.getBurnerCurrentLimit(_minter), 0);
  }

  function testCurrentLimitIsMaxLimitIfUnused(uint256 _limit, address _minter) public {
    uint256 _currentTimestamp = 1_683_145_698;
    vm.warp(_currentTimestamp);

    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_limit, _minter);
    _xerc20.changeBurnerLimit(_limit, _minter);
    vm.stopPrank();

    vm.warp(_currentTimestamp + 12 hours);

    assertEq(_xerc20.getMinterCurrentLimit(_minter), _limit);
    assertEq(_xerc20.getBurnerCurrentLimit(_minter), _limit);
  }

  function testCurrentLimitIsMaxLimitIfOver24Hours(uint256 _limit, address _minter) public {
    uint256 _currentTimestamp = 1_683_145_698;
    vm.warp(_currentTimestamp);
    vm.assume(_minter != address(0));

    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_limit, _minter);
    _xerc20.changeBurnerLimit(_limit, _minter);
    vm.stopPrank();

    vm.startPrank(_minter);
    _xerc20.mint(_minter, _limit);
    _xerc20.burn(_minter, _limit);
    vm.stopPrank();

    vm.warp(_currentTimestamp + 30 hours);

    assertEq(_xerc20.getMinterCurrentLimit(_minter), _limit);
    assertEq(_xerc20.getBurnerCurrentLimit(_minter), _limit);
  }

  function testLimitVestsLinearly(uint256 _limit, address _minter) public {
    vm.assume(_limit > 1e6);
    vm.assume(_minter != address(0));
    uint256 _currentTimestamp = 1_683_145_698;
    vm.warp(_currentTimestamp);

    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_limit, _minter);
    _xerc20.changeBurnerLimit(_limit, _minter);
    vm.stopPrank();

    vm.startPrank(_minter);
    _xerc20.mint(_minter, _limit);
    _xerc20.burn(_minter, _limit);
    vm.stopPrank();

    vm.warp(_currentTimestamp + 12 hours);

    assertApproxEqRel(_xerc20.getMinterCurrentLimit(_minter), _limit / 2, 0.1 ether);
    assertApproxEqRel(_xerc20.getBurnerCurrentLimit(_minter), _limit / 2, 0.1 ether);
  }

  function testOverflowLimitMakesItMax(uint256 _limit, address _minter, uint256 _usedLimit) public {
    _limit = bound(_limit, 1e6, 100_000_000_000_000e18);
    vm.assume(_usedLimit < 1e3);
    vm.assume(_minter != address(0));
    uint256 _currentTimestamp = 1_683_145_698;
    vm.warp(_currentTimestamp);

    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_limit, _minter);
    _xerc20.changeBurnerLimit(_limit, _minter);
    vm.stopPrank();

    vm.startPrank(_minter);
    _xerc20.mint(_minter, _usedLimit);
    _xerc20.burn(_minter, _usedLimit);
    vm.stopPrank();

    vm.warp(_currentTimestamp + 20 hours);

    assertEq(_xerc20.getMinterCurrentLimit(_minter), _limit);
    assertEq(_xerc20.getBurnerCurrentLimit(_minter), _limit);
  }

  function testChangeMinterLimitIncreaseCurrentLimitByTheDifferenceItWasChanged(
    uint256 _limit,
    address _minter,
    uint256 _usedLimit
  ) public {
    vm.assume(_limit < 1e40);
    vm.assume(_usedLimit < 1e3);
    vm.assume(_limit > _usedLimit);
    vm.assume(_minter != address(0));
    uint256 _currentTimestamp = 1_683_145_698;
    vm.warp(_currentTimestamp);

    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_limit, _minter);
    _xerc20.changeBurnerLimit(_limit, _minter);
    vm.stopPrank();

    vm.startPrank(_minter);
    _xerc20.mint(_minter, _usedLimit);
    _xerc20.burn(_minter, _usedLimit);
    vm.stopPrank();

    vm.startPrank(_owner);
    // Adding 100k to the limit
    _xerc20.changeMinterLimit(_limit + 100_000, _minter);
    _xerc20.changeBurnerLimit(_limit + 100_000, _minter);
    vm.stopPrank();

    assertEq(_xerc20.getMinterCurrentLimit(_minter), (_limit - _usedLimit) + 100_000);
  }

  function testChangeMinterLimitDecreaseCurrentLimitByTheDifferenceItWasChanged(
    uint256 _limit,
    address _minter,
    uint256 _usedLimit
  ) public {
    vm.assume(_minter != address(0));
    uint256 _currentTimestamp = 1_683_145_698;
    vm.warp(_currentTimestamp);
    _limit = bound(_limit, 1e15, 1e40);
    _usedLimit = bound(_usedLimit, 100_000, 1e9);

    vm.startPrank(_owner);
    // Setting the limit at its original limit
    _xerc20.changeMinterLimit(_limit, _minter);
    _xerc20.changeBurnerLimit(_limit, _minter);
    vm.stopPrank();

    vm.startPrank(_minter);
    _xerc20.mint(_minter, _usedLimit);
    _xerc20.burn(_minter, _usedLimit);
    vm.stopPrank();

    vm.startPrank(_owner);
    // Removing 100k to the limit
    _xerc20.changeMinterLimit(_limit - 100_000, _minter);
    _xerc20.changeBurnerLimit(_limit - 100_000, _minter);
    vm.stopPrank();

    assertEq(_xerc20.getMinterCurrentLimit(_minter), (_limit - _usedLimit) - 100_000);
    assertEq(_xerc20.getBurnerCurrentLimit(_minter), (_limit - _usedLimit) - 100_000);
  }

  function testCreateParamsUpdatesLimit(uint256 _originalLimit, uint256 _newLimit) public {
    vm.assume(_originalLimit > 0);
    vm.assume(_newLimit > 0 && _newLimit != _originalLimit);

    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_originalLimit, _minter);
    _xerc20.changeBurnerLimit(_originalLimit, _minter);
    vm.stopPrank();

    uint256[] memory _limits = new uint256[](1);
    address[] memory _minters = new address[](1);

    _limits[0] = _newLimit;
    _minters[0] = _minter;

    vm.startPrank(_owner);
    _xerc20.createMinterLimits(_limits, _minters);
    _xerc20.createBurnerLimits(_limits, _minters);
    vm.stopPrank();

    assertEq(_xerc20.getMinterMaxLimit(_minter), _newLimit);
    assertEq(_xerc20.getBurnerMaxLimit(_minter), _newLimit);
  }

  function testChangingUsedLimitsToZero(uint256 _limit, uint256 _amount) public {
    _limit = bound(_limit, 1, 1e40);
    vm.assume(_amount < _limit);
    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(_limit, _minter);
    _xerc20.changeBurnerLimit(_limit, _minter);
    vm.stopPrank();

    vm.startPrank(_minter);
    _xerc20.mint(_minter, _amount);
    _xerc20.burn(_minter, _amount);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.changeMinterLimit(0, _minter);
    _xerc20.changeBurnerLimit(0, _minter);
    vm.stopPrank();

    assertEq(_xerc20.getMinterMaxLimit(_minter), 0);
    assertEq(_xerc20.getMinterCurrentLimit(_minter), 0);
    assertEq(_xerc20.getBurnerMaxLimit(_minter), 0);
    assertEq(_xerc20.getBurnerCurrentLimit(_minter), 0);
  }

  function testSetLockbox(address _lockbox) public {
    vm.prank(_owner);
    _xerc20.setLockbox(_lockbox);

    assertEq(_xerc20.lockbox(), _lockbox);
  }

  function testLockboxDoesntNeedMinterRights(address _lockbox) public {
    vm.assume(_lockbox != address(0));
    vm.prank(_owner);
    _xerc20.setLockbox(_lockbox);

    vm.startPrank(_lockbox);
    _xerc20.mint(_lockbox, 10);
    assertEq(_xerc20.balanceOf(_lockbox), 10);
    _xerc20.burn(_lockbox, 10);
    assertEq(_xerc20.balanceOf(_lockbox), 0);
    vm.stopPrank();
  }
}
