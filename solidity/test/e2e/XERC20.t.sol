// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {CommonE2EBase} from './Common.sol';
import {XERC20Lockbox} from 'contracts/XERC20Lockbox.sol';
import {XERC20, IXERC20} from 'contracts/XERC20.sol';

contract E2EMintAndBurn is CommonE2EBase {
  function testMint() public {
    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(100 ether, _owner);
    _xerc20.mint(_user, 100 ether);
    vm.stopPrank();

    assertEq(_xerc20.balanceOf(_user), 100 ether);
  }

  function testBurn() public {
    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(100 ether, _owner);
    _xerc20.changeBridgeBurningLimit(100 ether, _owner);
    _xerc20.mint(_user, 100 ether);
    _xerc20.burn(_user, 100 ether);
    vm.stopPrank();

    assertEq(_xerc20.balanceOf(_user), 0);
    assertEq(_xerc20.totalSupply(), 0);
  }

  function testTransferMint() public {
    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(100 ether, _owner);
    _xerc20.transfer(_user, 100 ether);
    vm.stopPrank();

    assertEq(_xerc20.balanceOf(_user), 100 ether);
  }

  function testTransferBurn() public {
    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(100 ether, _owner);
    _xerc20.changeBridgeBurningLimit(100 ether, _owner);
    _xerc20.transfer(_user, 100 ether);
    vm.stopPrank();

    vm.prank(_user);
    _xerc20.transfer(_owner, 100 ether);

    assertEq(_xerc20.balanceOf(_user), 0);
    assertEq(_xerc20.totalSupply(), 0);
  }

  function testTransferFromMint() public {
    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(100 ether, _owner);
    _xerc20.approve(_owner, 100 ether);
    _xerc20.transferFrom(_owner, _user, 100 ether);
    vm.stopPrank();

    assertEq(_xerc20.balanceOf(_user), 100 ether);
  }

  function testTransferFromBurn() public {
    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(100 ether, _owner);
    _xerc20.changeBridgeBurningLimit(100 ether, _owner);
    _xerc20.approve(_owner, 100 ether);
    _xerc20.transferFrom(_owner, _user, 100 ether);
    vm.stopPrank();

    vm.startPrank(_user);
    _xerc20.approve(_user, 100 ether);
    _xerc20.transferFrom(_user, _owner, 100 ether);
    vm.stopPrank();

    assertEq(_xerc20.balanceOf(_user), 0);
    assertEq(_xerc20.totalSupply(), 0);
  }

  function testTwoBridgesTransfer() public {
    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(100 ether, _owner);
    _xerc20.changeBridgeBurningLimit(100 ether, _user);
    _xerc20.transfer(_user, 100 ether);
    vm.stopPrank();

    assertEq(_xerc20.balanceOf(_user), 0);
    assertEq(_xerc20.balanceOf(_owner), 0);
    assertEq(_xerc20.totalSupply(), 0);
    assertEq(_xerc20.mintingCurrentLimitOf(_user), 0);
    assertEq(_xerc20.burningCurrentLimitOf(_owner), 0);
  }
}

contract E2EParameterMath is CommonE2EBase {
  function testChangeLimit() public {
    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(100 ether, _owner);
    _xerc20.changeBridgeBurningLimit(100 ether, _owner);
    vm.stopPrank();

    assertEq(_xerc20.mintingMaxLimitOf(_owner), 100 ether);
    assertEq(_xerc20.burningMaxLimitOf(_owner), 100 ether);
  }

  function testAddingMintersAndLimits() public {
    uint256[] memory _limits = new uint256[](3);
    address[] memory _minters = new address[](3);

    _limits[0] = 100 ether;
    _limits[1] = 100 ether;
    _limits[2] = 100 ether;

    _minters[0] = vm.addr(1);
    _minters[1] = vm.addr(2);
    _minters[2] = vm.addr(3);

    vm.startPrank(_owner);
    _xerc20.createBridgeMintingLimits(_limits, _minters);
    _xerc20.createBridgeBurningLimits(_limits, _minters);
    vm.stopPrank();

    assertEq(_xerc20.mintingMaxLimitOf(vm.addr(1)), 100 ether);
    assertEq(_xerc20.mintingMaxLimitOf(vm.addr(2)), 100 ether);
    assertEq(_xerc20.mintingMaxLimitOf(vm.addr(3)), 100 ether);
  }

  function testUseLimitsUpdatesLimit() public {
    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(100 ether, _owner);
    _xerc20.changeBridgeBurningLimit(100 ether, _owner);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.mint(_user, 100 ether);
    _xerc20.burn(_user, 100 ether);
    vm.stopPrank();

    assertEq(_xerc20.mintingCurrentLimitOf(_owner), 0);
    assertEq(_xerc20.burningCurrentLimitOf(_owner), 0);
  }

  function testChangingMaxLimitUpdatesCurrentLimit() public {
    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(100 ether, _owner);
    _xerc20.changeBridgeBurningLimit(100 ether, _owner);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(50 ether, _owner);
    _xerc20.changeBridgeBurningLimit(50 ether, _owner);
    vm.stopPrank();

    assertEq(_xerc20.mintingCurrentLimitOf(_owner), 50 ether);
    assertEq(_xerc20.burningCurrentLimitOf(_owner), 50 ether);
  }

  function testChangingMaxLimitWhenLimitIsUsedUpdatesCurrentLimit() public {
    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(100 ether, _owner);
    _xerc20.changeBridgeBurningLimit(100 ether, _owner);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.mint(_user, 100 ether);
    _xerc20.burn(_user, 100 ether);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(50 ether, _owner);
    _xerc20.changeBridgeBurningLimit(50 ether, _owner);
    vm.stopPrank();

    assertEq(_xerc20.mintingCurrentLimitOf(_owner), 0);
    assertEq(_xerc20.burningCurrentLimitOf(_owner), 0);
  }

  function testChangingPartialMaxLimitUpdatesCurrentLimitWhenUsed() public {
    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(100 ether, _owner);
    _xerc20.changeBridgeBurningLimit(100 ether, _owner);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.mint(_user, 10 ether);
    _xerc20.burn(_user, 10 ether);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(50 ether, _owner);
    _xerc20.changeBridgeBurningLimit(50 ether, _owner);
    vm.stopPrank();

    assertEq(_xerc20.mintingCurrentLimitOf(_owner), 40 ether);
    assertEq(_xerc20.burningCurrentLimitOf(_owner), 40 ether);
  }

  function testChangingPartialMaxLimitUpdatesCurrentLimitWithIncrease() public {
    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(100 ether, _owner);
    _xerc20.changeBridgeBurningLimit(100 ether, _owner);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.mint(_user, 10 ether);
    _xerc20.burn(_user, 10 ether);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(120 ether, _owner);
    _xerc20.changeBridgeBurningLimit(120 ether, _owner);
    vm.stopPrank();

    assertEq(_xerc20.mintingCurrentLimitOf(_owner), 110 ether);
    assertEq(_xerc20.burningCurrentLimitOf(_owner), 110 ether);
  }

  function testCurrentLimitIsUpdatedWithTime() public {
    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(100 ether, _owner);
    _xerc20.changeBridgeBurningLimit(100 ether, _owner);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.mint(_user, 100 ether);
    _xerc20.burn(_user, 100 ether);
    vm.stopPrank();

    // Move block.timestamp forward 12 hours
    vm.warp(block.timestamp + 12 hours);

    assertApproxEqRel(_xerc20.mintingCurrentLimitOf(_owner), 100 ether / 2, 0.1 ether);
    assertApproxEqRel(_xerc20.burningCurrentLimitOf(_owner), 100 ether / 2, 0.1 ether);
  }

  function testCurrentLimitIsMaxAfterDuration() public {
    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(100 ether, _owner);
    _xerc20.changeBridgeBurningLimit(100 ether, _owner);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.mint(_user, 100 ether);
    _xerc20.burn(_user, 100 ether);
    vm.stopPrank();

    // Move block.timestamp forward 25 hours
    vm.warp(block.timestamp + 25 hours);

    assertEq(_xerc20.mintingCurrentLimitOf(_owner), 100 ether);
    assertEq(_xerc20.burningCurrentLimitOf(_owner), 100 ether);
  }

  function testCurrentLimitIsSameIfUnused() public {
    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(100 ether, _owner);
    _xerc20.changeBridgeBurningLimit(100 ether, _owner);
    vm.stopPrank();

    // Move block.timestamp forward 12 hours
    vm.warp(block.timestamp + 12 hours);

    assertEq(_xerc20.mintingCurrentLimitOf(_owner), 100 ether);
    assertEq(_xerc20.burningCurrentLimitOf(_owner), 100 ether);
  }

  function testMultipleUsersUseBridge() public {
    address _user0 = vm.addr(1);
    address _user1 = vm.addr(2);
    address _user2 = vm.addr(3);
    address _user3 = vm.addr(4);
    address _user4 = vm.addr(5);

    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(100 ether, _owner);
    _xerc20.changeBridgeBurningLimit(100 ether, _owner);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.mint(_user0, 10 ether);
    _xerc20.mint(_user1, 10 ether);
    _xerc20.mint(_user2, 10 ether);
    _xerc20.mint(_user3, 10 ether);
    _xerc20.mint(_user4, 10 ether);
    vm.stopPrank();

    assertEq(_xerc20.mintingCurrentLimitOf(_owner), 50 ether);

    vm.warp(block.timestamp + 12 hours);

    assertApproxEqRel(_xerc20.mintingCurrentLimitOf(_owner), 50 ether + (100 ether / 2), 0.1 ether);
  }

  function testMultipleMintsAndBurns() public {
    address _user0 = vm.addr(1);
    address _user1 = vm.addr(2);
    address _user2 = vm.addr(3);
    address _user3 = vm.addr(4);
    address _user4 = vm.addr(5);

    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(100 ether, _owner);
    _xerc20.changeBridgeBurningLimit(100 ether, _owner);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.mint(_user0, 20 ether);
    _xerc20.mint(_user1, 10 ether);
    _xerc20.mint(_user2, 20 ether);
    _xerc20.mint(_user3, 10 ether);
    _xerc20.mint(_user4, 20 ether);
    vm.stopPrank();

    assertEq(_xerc20.mintingCurrentLimitOf(_owner), 20 ether);

    vm.startPrank(_owner);
    _xerc20.burn(_user0, 5 ether);
    _xerc20.burn(_user1, 5 ether);
    _xerc20.burn(_user2, 5 ether);
    _xerc20.burn(_user3, 5 ether);
    _xerc20.burn(_user4, 5 ether);
    vm.stopPrank();

    assertEq(_xerc20.burningCurrentLimitOf(_owner), 75 ether);

    vm.warp(block.timestamp + 12 hours);

    assertApproxEqRel(_xerc20.mintingCurrentLimitOf(_owner), 20 ether + (100 ether / 2), 0.1 ether);
    assertEq(_xerc20.burningCurrentLimitOf(_owner), 100 ether);
  }

  function testTransferAndMintAreInterchangeable() public {
    address _user0 = vm.addr(1);
    address _user1 = vm.addr(2);
    address _user2 = vm.addr(3);
    address _user3 = vm.addr(4);
    address _user4 = vm.addr(5);

    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(100 ether, _owner);
    _xerc20.changeBridgeBurningLimit(100 ether, _owner);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.mint(_user0, 20 ether);
    _xerc20.mint(_user1, 10 ether);
    _xerc20.mint(_user2, 20 ether);
    _xerc20.transfer(_user3, 10 ether);
    _xerc20.transfer(_user4, 20 ether);
    vm.stopPrank();

    assertEq(_xerc20.mintingCurrentLimitOf(_owner), 20 ether);

    vm.startPrank(_owner);
    _xerc20.burn(_user0, 5 ether);
    _xerc20.burn(_user1, 5 ether);
    _xerc20.burn(_user2, 5 ether);
    vm.stopPrank();

    vm.prank(_user3);
    _xerc20.transfer(_owner, 5 ether);

    vm.prank(_user4);
    _xerc20.transfer(_owner, 5 ether);

    assertEq(_xerc20.burningCurrentLimitOf(_owner), 75 ether);

    vm.warp(block.timestamp + 12 hours);

    assertApproxEqRel(_xerc20.mintingCurrentLimitOf(_owner), 20 ether + (100 ether / 2), 0.1 ether);
    assertEq(_xerc20.burningCurrentLimitOf(_owner), 100 ether);
  }

  function testMultipleBridgesHaveDifferentValue() public {
    address _user = vm.addr(1);
    uint256 _ownerLimit = 100 ether;
    uint256 _userLimit = 50 ether;

    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(_ownerLimit, _owner);
    _xerc20.changeBridgeMintingLimit(_userLimit, _user);
    _xerc20.changeBridgeBurningLimit(_ownerLimit, _owner);
    _xerc20.changeBridgeBurningLimit(_userLimit, _user);
    vm.stopPrank();

    uint256 _ownerExpectedRps = _ownerLimit / (24 hours);
    uint256 _userExpectedRps = _userLimit / (24 hours);

    vm.startPrank(_owner);
    _xerc20.mint(_user, 90 ether);
    _xerc20.burn(_user, 90 ether);
    vm.stopPrank();

    vm.startPrank(_user);
    _xerc20.mint(_owner, 40 ether);
    _xerc20.burn(_owner, 40 ether);
    vm.stopPrank();

    (, IXERC20.BridgeParameters memory _ownerMinterParams,) = _xerc20.bridges(_owner);
    (, IXERC20.BridgeParameters memory _userMinterParams,) = _xerc20.bridges(_user);

    assertEq(_ownerMinterParams.maxLimit, _ownerLimit);
    assertEq(_ownerMinterParams.currentLimit, _ownerLimit - 90 ether);
    assertEq(_userMinterParams.maxLimit, _userLimit);
    assertEq(_userMinterParams.currentLimit, _userLimit - 40 ether);
    assertEq(_ownerMinterParams.timestamp, block.timestamp);
    assertEq(_userMinterParams.timestamp, block.timestamp);
    assertEq(_userMinterParams.ratePerSecond, _userExpectedRps);
    assertEq(_ownerMinterParams.ratePerSecond, _ownerExpectedRps);

    vm.warp(block.timestamp + 12 hours);

    assertApproxEqRel(_xerc20.mintingCurrentLimitOf(_owner), _ownerLimit - 90 ether + (_ownerLimit / 2), 0.1 ether);
    assertApproxEqRel(_xerc20.mintingCurrentLimitOf(_user), _userLimit - 40 ether + (_userLimit / 2), 0.1 ether);

    assertApproxEqRel(_xerc20.burningCurrentLimitOf(_owner), _ownerLimit - 90 ether + (_ownerLimit / 2), 0.1 ether);
    assertApproxEqRel(_xerc20.burningCurrentLimitOf(_user), _userLimit - 40 ether + (_userLimit / 2), 0.1 ether);
  }

  function testMultipleBridgesBurnsHaveDifferentValues() public {
    address _user = vm.addr(1);
    uint256 _ownerLimit = 100 ether;
    uint256 _userLimit = 50 ether;

    vm.startPrank(_owner);
    _xerc20.changeBridgeMintingLimit(_ownerLimit, _owner);
    _xerc20.changeBridgeMintingLimit(_userLimit, _user);
    _xerc20.changeBridgeBurningLimit(_ownerLimit, _owner);
    _xerc20.changeBridgeBurningLimit(_userLimit, _user);
    vm.stopPrank();

    uint256 _ownerExpectedRps = _ownerLimit / (24 hours);
    uint256 _userExpectedRps = _userLimit / (24 hours);

    vm.startPrank(_owner);
    _xerc20.mint(_user, 90 ether);
    _xerc20.burn(_user, 50 ether);
    vm.stopPrank();

    vm.startPrank(_user);
    _xerc20.mint(_owner, 40 ether);
    _xerc20.burn(_owner, 25 ether);
    vm.stopPrank();

    (,, IXERC20.BridgeParameters memory _ownerBurnerParams) = _xerc20.bridges(_owner);
    (,, IXERC20.BridgeParameters memory _userBurnerParams) = _xerc20.bridges(_user);

    assertEq(_ownerBurnerParams.maxLimit, _ownerLimit);
    assertEq(_ownerBurnerParams.currentLimit, _ownerLimit - 50 ether);
    assertEq(_userBurnerParams.maxLimit, _userLimit);
    assertEq(_userBurnerParams.currentLimit, _userLimit - 25 ether);
    assertEq(_ownerBurnerParams.timestamp, block.timestamp);
    assertEq(_userBurnerParams.timestamp, block.timestamp);
    assertEq(_userBurnerParams.ratePerSecond, _userExpectedRps);
    assertEq(_ownerBurnerParams.ratePerSecond, _ownerExpectedRps);

    vm.warp(block.timestamp + 12 hours);

    assertApproxEqRel(_xerc20.mintingCurrentLimitOf(_owner), _ownerLimit - 90 ether + (_ownerLimit / 2), 0.1 ether);
    assertApproxEqRel(_xerc20.mintingCurrentLimitOf(_user), _userLimit - 40 ether + (_userLimit / 2), 0.1 ether);

    assertApproxEqRel(_xerc20.burningCurrentLimitOf(_owner), _ownerLimit - 50 ether + (_ownerLimit / 2), 0.1 ether);
    assertApproxEqRel(_xerc20.burningCurrentLimitOf(_user), _userLimit - 25 ether + (_userLimit / 2), 0.1 ether);
  }
}
