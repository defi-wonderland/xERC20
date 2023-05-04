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

  event ChainIdsCreated(uint256[] _chainId);
  event LimitsCreated(uint256[] _limits, address[] _minters);
  event LimitsChanged(uint256 _oldLimit, uint256 _newLimit, address _minter);
  event ChainIdAdded(uint256 _newChainId);

  function setUp() public virtual {
    vm.startPrank(_owner);
    _xerc20 = new XERC20('Test', 'TST');
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
    vm.prank(_user);
    vm.expectRevert(IXERC20.IXERC20_NotApprovedMinter.selector);
    _xerc20.mint(_user, _amount);
  }

  function testBurnRevertsWhenLimitIsTooLow(uint256 _amount0, uint256 _amount1) public {
    _amount0 = bound(_amount0, 1, 1e40);
    _amount1 = bound(_amount1, 1, 1e40);
    vm.assume(_amount1 > _amount0);
    vm.prank(_owner);
    _xerc20.changeLimit(_amount0, _user);

    vm.startPrank(_user);
    _xerc20.mint(_user, _amount1);
    vm.expectRevert(IXERC20.IXERC20_NotHighEnoughLimits.selector);
    _xerc20.burn(_user, _amount1);
    vm.stopPrank();
  }

  function testMint(uint256 _amount) public {
    vm.assume(_amount > 0);

    vm.prank(_owner);
    _xerc20.changeLimit(_amount, _user);
    vm.prank(_user);
    _xerc20.mint(_user, _amount);

    assertEq(_xerc20.balanceOf(_user), _amount);
  }

  function testBurn(uint256 _amount) public {
    _amount = bound(_amount, 1, 1e40);
    vm.prank(_owner);
    _xerc20.changeLimit(_amount, _user);

    vm.startPrank(_user);
    _xerc20.mint(_user, _amount);
    _xerc20.burn(_user, _amount);
    vm.stopPrank();

    assertEq(_xerc20.balanceOf(_user), 0);
  }

  function testCanStillMintWhenLimitIsReached(uint256 _amount) public {
    _amount = bound(_amount, 1, 10_000);
    vm.prank(_owner);
    _xerc20.changeLimit(_amount, _user);

    vm.startPrank(_user);
    _xerc20.mint(_user, _amount);
    _xerc20.burn(_user, _amount);

    _xerc20.mint(_user, _amount);
    vm.stopPrank();

    assertEq(_xerc20.balanceOf(_user), _amount);
  }
}

contract UnitCreateParams is Base {
  function testCreateParam(uint256 _newChainId, uint256 _limit, address _minter) public {
    vm.assume(_limit > 0);
    uint256[] memory _chainId = new uint256[](1);
    uint256[] memory _limits = new uint256[](1);
    address[] memory _minters = new address[](1);

    _chainId[0] = _newChainId;
    _limits[0] = _limit;
    _minters[0] = _minter;

    vm.startPrank(_owner);
    _xerc20.createLimits(_limits, _minters);
    _xerc20.createChainIds(_chainId);
    vm.stopPrank();

    assertEq(_xerc20.getMaxLimit(_minter), _limit);
    assertEq(_xerc20.isMinterApproved(_minter), true);
    assertEq(_xerc20.getChainIdStatus(_newChainId), true);
  }

  function testChangeLimit(uint256 _amount, address _randomAddr) public {
    vm.startPrank(_owner);
    _xerc20.changeLimit(_amount, _randomAddr);
    vm.stopPrank();
    assertEq(_xerc20.getMaxLimit(_randomAddr), _amount);
  }

  function testAddChainId(uint256 _newChainId) public {
    vm.startPrank(_owner);
    _xerc20.addChainId(_newChainId);
    vm.stopPrank();
    assertEq(_xerc20.getChainIdStatus(_newChainId), true);
  }

  function testBadChainIdIsFalse(uint256 _badChainId) public {
    assertEq(_xerc20.getChainIdStatus(_badChainId), false);
  }

  function testCreationWithChainIds(uint256 _id1, uint256 _id2, uint256 _id3) public {
    uint256[] memory _chainId = new uint256[](3);
    _chainId[0] = _id1;
    _chainId[1] = _id2;
    _chainId[2] = _id3;

    vm.prank(_owner);
    _xerc20.createChainIds(_chainId);

    assertEq(_xerc20.getChainIdStatus(_id1), true);
    assertEq(_xerc20.getChainIdStatus(_id2), true);
    assertEq(_xerc20.getChainIdStatus(_id3), true);
  }

  function testRevertsWithWrongCaller() public {
    vm.expectRevert('Ownable: caller is not the owner');
    _xerc20.addChainId(100);
    vm.expectRevert('Ownable: caller is not the owner');
    _xerc20.changeLimit(1e18, _minter);
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

    vm.prank(_owner);
    _xerc20.createLimits(_limits, _minters);

    assertEq(_xerc20.getMaxLimit(_user0), _amount0);
    assertEq(_xerc20.getMaxLimit(_user1), _amount1);
    assertEq(_xerc20.getMaxLimit(_user2), _amount2);
  }

  function testCreateLimitsEmitsEvent() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.expectEmit(true, true, true, true);
    emit LimitsCreated(_limits, _minters);
    vm.prank(_owner);
    _xerc20.createLimits(_limits, _minters);
  }

  function testCreateChainIdsEmitsEvent() public {
    uint256[] memory _chainId = new uint256[](0);

    vm.expectEmit(true, true, true, true);
    emit ChainIdsCreated(_chainId);
    vm.prank(_owner);
    _xerc20.createChainIds(_chainId);
  }

  function testAddChainIdEmitsEvent(uint256 _newChainId) public {
    vm.startPrank(_owner);
    vm.expectEmit(true, true, true, true);
    emit ChainIdAdded(_newChainId);
    _xerc20.addChainId(_newChainId);
  }

  function testChangeLimitEmitsEvent(uint256 _limit, address _minter) public {
    vm.prank(_owner);
    vm.expectEmit(true, true, true, true);
    emit LimitsChanged(0, _limit, _minter);
    _xerc20.changeLimit(_limit, _minter);
  }

  function testSettingLimitsToUnapprovedMinter(uint256 _amount) public {
    vm.assume(_amount > 0);

    vm.startPrank(_owner);
    _xerc20.changeLimit(_amount, _minter);
    vm.stopPrank();

    assertEq(_xerc20.getMaxLimit(_minter), _amount);
    assertEq(_xerc20.isMinterApproved(_minter), true);
  }

  function testUseLimitsUpdatesLimit(uint256 _limit, address _minter) public {
    vm.assume(_limit > 1e6);
    vm.assume(_minter != address(0));
    vm.warp(1_683_145_698); // current timestamp at the time of testing

    vm.startPrank(_owner);
    _xerc20.changeLimit(_limit, _minter);
    vm.stopPrank();

    _xerc20.mint(_minter, _limit);
    _xerc20.burn(_minter, _limit);

    assertEq(_xerc20.getMaxLimit(_minter), _limit);
    assertEq(_xerc20.getCurrentLimit(_minter), 0);
  }

  function testCurrentLimitIsMaxLimitIfUnused(uint256 _limit, address _minter) public {
    uint256 _currentTimestamp = 1_683_145_698;
    vm.warp(_currentTimestamp);

    vm.startPrank(_owner);
    _xerc20.changeLimit(_limit, _minter);
    vm.stopPrank();

    vm.warp(_currentTimestamp + 12 hours);

    assertEq(_xerc20.getCurrentLimit(_minter), _limit);
  }

  function testCurrentLimitIsMaxLimitIfOver24Hours(uint256 _limit, address _minter) public {
    uint256 _currentTimestamp = 1_683_145_698;
    vm.warp(_currentTimestamp);

    vm.startPrank(_owner);
    _xerc20.changeLimit(_limit, _minter);
    vm.stopPrank();

    vm.warp(_currentTimestamp + 30 hours);

    assertEq(_xerc20.getCurrentLimit(_minter), _limit);
  }

  function testLimitVestsLinearly(uint256 _limit, address _minter) public {
    vm.assume(_limit > 1e6);
    vm.assume(_minter != address(0));
    uint256 _currentTimestamp = 1_683_145_698;
    vm.warp(_currentTimestamp);

    vm.startPrank(_owner);
    _xerc20.changeLimit(_limit, _minter);
    vm.stopPrank();

    _xerc20.mint(_minter, _limit);
    _xerc20.burn(_minter, _limit);

    vm.warp(_currentTimestamp + 12 hours);

    assertApproxEqRel(_xerc20.getCurrentLimit(_minter), _limit / 2, 0.1 ether);
  }

  function testOverflowLimitMakesItMax(uint256 _limit, address _minter, uint256 _usedLimit) public {
    _limit = bound(_limit, 1e6, 100_000_000_000_000e18);
    vm.assume(_usedLimit < 1e3);
    vm.assume(_minter != address(0));
    uint256 _currentTimestamp = 1_683_145_698;
    vm.warp(_currentTimestamp);

    vm.startPrank(_owner);
    _xerc20.changeLimit(_limit, _minter);
    vm.stopPrank();

    _xerc20.mint(_minter, _limit);
    _xerc20.burn(_minter, _usedLimit);

    vm.warp(_currentTimestamp + 20 hours);

    assertEq(_xerc20.getCurrentLimit(_minter), _limit);
  }

  function testChangeLimitIncreaseCurrentLimitByTheDifferenceItWasChanged(
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
    // Setting the limit at its original limit
    _xerc20.changeLimit(_limit, _minter);

    _xerc20.mint(_minter, _limit);
    _xerc20.burn(_minter, _usedLimit);
    // Adding 100k to the limit
    _xerc20.changeLimit(_limit + 100_000, _minter);
    vm.stopPrank();

    assertEq(_xerc20.getCurrentLimit(_minter), (_limit - _usedLimit) + 100_000);
  }

  function testChangeLimitDecreaseCurrentLimitByTheDifferenceItWasChanged(
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
    _xerc20.changeLimit(_limit, _minter);

    _xerc20.mint(_minter, _limit);
    _xerc20.burn(_minter, _usedLimit);
    // Removing 100k to the limit
    _xerc20.changeLimit(_limit - 100_000, _minter);
    vm.stopPrank();

    assertEq(_xerc20.getCurrentLimit(_minter), (_limit - _usedLimit) - 100_000);
  }

  function testCreateParamsUpdatesLimit(uint256 _originalLimit, uint256 _newLimit) public {
    vm.assume(_originalLimit > 0);
    vm.assume(_newLimit > 0 && _newLimit != _originalLimit);

    vm.prank(_owner);
    _xerc20.changeLimit(_originalLimit, _minter);

    uint256[] memory _limits = new uint256[](1);
    address[] memory _minters = new address[](1);

    _limits[0] = _newLimit;
    _minters[0] = _minter;

    vm.prank(_owner);
    _xerc20.createLimits(_limits, _minters);

    assertEq(_xerc20.getMaxLimit(_minter), _newLimit);
  }

  function changeLimitRemovesMinterRightsIfChangedToZero() public {
    vm.startPrank(_owner);
    _xerc20.changeLimit(1, _minter);
    _xerc20.changeLimit(0, _minter);
    vm.stopPrank();

    assertEq(_xerc20.isMinterApproved(_minter), false);
  }

  function testChangingUsedLimitsToZero(uint256 _limit, uint256 _amount) public {
    _limit = bound(_limit, 1, 1e40);
    vm.assume(_amount < _limit);
    vm.prank(_owner);
    _xerc20.changeLimit(_limit, _minter);

    vm.startPrank(_minter);
    _xerc20.mint(_minter, _amount);
    _xerc20.burn(_minter, _amount);
    vm.stopPrank();

    vm.prank(_owner);
    _xerc20.changeLimit(0, _minter);

    assertEq(_xerc20.isMinterApproved(_minter), false);
    assertEq(_xerc20.getMaxLimit(_minter), 0);
    assertEq(_xerc20.getCurrentLimit(_minter), 0);
  }
}
