// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {CommonE2EBase} from './Common.sol';

contract E2EMintAndBurn is CommonE2EBase {
  function testMint() public {
    vm.startPrank(_owner);
    _xerc20.setLimits(_owner, 100 ether, 0);
    _xerc20.mint(_user, 100 ether);
    vm.stopPrank();

    assertEq(_xerc20.balanceOf(_user), 100 ether);
  }

  function testBurn() public {
    vm.startPrank(_owner);
    _xerc20.setLimits(_owner, 100 ether, 100 ether);

    _xerc20.mint(_user, 100 ether);
    vm.stopPrank();

    vm.prank(_user);
    _xerc20.approve(_owner, 100 ether);

    vm.prank(_owner);
    _xerc20.burn(_user, 100 ether);

    assertEq(_xerc20.balanceOf(_user), 0);
    assertEq(_xerc20.totalSupply(), 0);
  }
}

contract E2EParameterMath is CommonE2EBase {
  function testChangeLimit() public {
    vm.startPrank(_owner);
    _xerc20.setLimits(_owner, 100 ether, 100 ether);
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
    for (uint256 _i = 0; _i < _minters.length; _i++) {
      _xerc20.setLimits(_minters[_i], _limits[_i], _limits[_i]);
    }
    vm.stopPrank();

    assertEq(_xerc20.mintingMaxLimitOf(vm.addr(1)), 100 ether);
    assertEq(_xerc20.mintingMaxLimitOf(vm.addr(2)), 100 ether);
    assertEq(_xerc20.mintingMaxLimitOf(vm.addr(3)), 100 ether);
  }

  function testUseLimitsUpdatesLimit() public {
    vm.startPrank(_owner);
    _xerc20.setLimits(_owner, 100 ether, 100 ether);
    vm.stopPrank();

    vm.prank(_user);
    _xerc20.approve(_owner, 100 ether);

    vm.startPrank(_owner);
    _xerc20.mint(_user, 100 ether);
    _xerc20.burn(_user, 100 ether);
    vm.stopPrank();

    assertEq(_xerc20.mintingCurrentLimitOf(_owner), 0);
    assertEq(_xerc20.burningCurrentLimitOf(_owner), 0);
  }

  function testChangingMaxLimitUpdatesCurrentLimit() public {
    vm.startPrank(_owner);
    _xerc20.setLimits(_owner, 100 ether, 100 ether);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.setLimits(_owner, 50 ether, 50 ether);
    vm.stopPrank();

    assertEq(_xerc20.mintingCurrentLimitOf(_owner), 50 ether);
    assertEq(_xerc20.burningCurrentLimitOf(_owner), 50 ether);
  }

  function testChangingMaxLimitWhenLimitIsUsedUpdatesCurrentLimit() public {
    vm.startPrank(_owner);
    _xerc20.setLimits(_owner, 100 ether, 100 ether);
    vm.stopPrank();

    vm.prank(_user);
    _xerc20.approve(_owner, 100 ether);

    vm.startPrank(_owner);
    _xerc20.mint(_user, 100 ether);
    _xerc20.burn(_user, 100 ether);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.setLimits(_owner, 50 ether, 50 ether);
    vm.stopPrank();

    assertEq(_xerc20.mintingCurrentLimitOf(_owner), 0);
    assertEq(_xerc20.burningCurrentLimitOf(_owner), 0);
  }

  function testChangingPartialMaxLimitUpdatesCurrentLimitWhenUsed() public {
    vm.startPrank(_owner);
    _xerc20.setLimits(_owner, 100 ether, 100 ether);
    vm.stopPrank();

    vm.prank(_user);
    _xerc20.approve(_owner, 100 ether);

    vm.startPrank(_owner);
    _xerc20.mint(_user, 10 ether);
    _xerc20.burn(_user, 10 ether);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.setLimits(_owner, 50 ether, 50 ether);
    vm.stopPrank();

    assertEq(_xerc20.mintingCurrentLimitOf(_owner), 40 ether);
    assertEq(_xerc20.burningCurrentLimitOf(_owner), 40 ether);
  }

  function testChangingPartialMaxLimitUpdatesCurrentLimitWithIncrease() public {
    vm.startPrank(_owner);
    _xerc20.setLimits(_owner, 100 ether, 100 ether);
    vm.stopPrank();

    vm.prank(_user);
    _xerc20.approve(_owner, 100 ether);

    vm.startPrank(_owner);
    _xerc20.mint(_user, 10 ether);
    _xerc20.burn(_user, 10 ether);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.setLimits(_owner, 120 ether, 120 ether);
    vm.stopPrank();

    assertEq(_xerc20.mintingCurrentLimitOf(_owner), 110 ether);
    assertEq(_xerc20.burningCurrentLimitOf(_owner), 110 ether);
  }

  function testCurrentLimitIsUpdatedWithTime() public {
    vm.startPrank(_owner);
    _xerc20.setLimits(_owner, 100 ether, 100 ether);
    vm.stopPrank();

    vm.prank(_user);
    _xerc20.approve(_owner, 100 ether);

    vm.prank(_user);
    _xerc20.approve(_owner, 100 ether);

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
    _xerc20.setLimits(_owner, 100 ether, 100 ether);
    vm.stopPrank();

    vm.prank(_user);
    _xerc20.approve(_owner, 100 ether);

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
    _xerc20.setLimits(_owner, 100 ether, 100 ether);
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
    _xerc20.setLimits(_owner, 100 ether, 100 ether);
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
    _xerc20.setLimits(_owner, 100 ether, 100 ether);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.mint(_user0, 20 ether);
    _xerc20.mint(_user1, 10 ether);
    _xerc20.mint(_user2, 20 ether);
    _xerc20.mint(_user3, 10 ether);
    _xerc20.mint(_user4, 20 ether);
    vm.stopPrank();

    assertEq(_xerc20.mintingCurrentLimitOf(_owner), 20 ether);

    vm.prank(_user0);
    _xerc20.approve(_owner, 100 ether);

    vm.prank(_user1);
    _xerc20.approve(_owner, 100 ether);

    vm.prank(_user2);
    _xerc20.approve(_owner, 100 ether);

    vm.prank(_user3);
    _xerc20.approve(_owner, 100 ether);

    vm.prank(_user4);
    _xerc20.approve(_owner, 100 ether);

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

  function testMultipleBridgesHaveDifferentValue() public {
    address _user = vm.addr(1);
    uint256 _ownerLimit = 100 ether;
    uint256 _userLimit = 50 ether;

    vm.startPrank(_owner);
    _xerc20.setLimits(_owner, _ownerLimit, _ownerLimit);
    _xerc20.setLimits(_user, _userLimit, _userLimit);
    vm.stopPrank();

    vm.prank(_user);
    _xerc20.approve(_owner, 100 ether);

    vm.prank(_owner);
    _xerc20.approve(_user, 100 ether);

    vm.startPrank(_owner);
    _xerc20.mint(_user, 90 ether);
    _xerc20.burn(_user, 90 ether);
    vm.stopPrank();

    vm.startPrank(_user);
    _xerc20.mint(_owner, 40 ether);
    _xerc20.burn(_owner, 40 ether);
    vm.stopPrank();

    uint256 _minterMaxLimitOwner = _xerc20.mintingMaxLimitOf(_owner);
    uint256 _minterMaxLimitUser = _xerc20.mintingMaxLimitOf(_user);

    uint256 _minterCurrentLimitOwner = _xerc20.mintingCurrentLimitOf(_owner);
    uint256 _minterCurrentLimitUser = _xerc20.mintingCurrentLimitOf(_user);

    assertEq(_minterMaxLimitOwner, _ownerLimit);
    assertEq(_minterCurrentLimitOwner, _ownerLimit - 90 ether);
    assertEq(_minterMaxLimitUser, _userLimit);
    assertEq(_minterCurrentLimitUser, _userLimit - 40 ether);

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

    vm.prank(_user);
    _xerc20.approve(_owner, 100 ether);

    vm.prank(_owner);
    _xerc20.approve(_user, 100 ether);

    vm.startPrank(_owner);
    _xerc20.setLimits(_owner, _ownerLimit, _ownerLimit);
    _xerc20.setLimits(_user, _userLimit, _userLimit);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc20.mint(_user, 90 ether);
    _xerc20.burn(_user, 50 ether);
    vm.stopPrank();

    vm.startPrank(_user);
    _xerc20.mint(_owner, 40 ether);
    _xerc20.burn(_owner, 25 ether);
    vm.stopPrank();

    uint256 _burnerMaxLimitOwner = _xerc20.burningMaxLimitOf(_owner);
    uint256 _burnerMaxLimitUser = _xerc20.burningMaxLimitOf(_user);

    uint256 _burnerCurrentLimitOwner = _xerc20.burningCurrentLimitOf(_owner);
    uint256 _burnerCurrentLimitUser = _xerc20.burningCurrentLimitOf(_user);

    assertEq(_burnerMaxLimitOwner, _ownerLimit);
    assertEq(_burnerCurrentLimitOwner, _ownerLimit - 50 ether);
    assertEq(_burnerMaxLimitUser, _userLimit);
    assertEq(_burnerCurrentLimitUser, _userLimit - 25 ether);

    vm.warp(block.timestamp + 12 hours);

    assertApproxEqRel(_xerc20.mintingCurrentLimitOf(_owner), _ownerLimit - 90 ether + (_ownerLimit / 2), 0.1 ether);
    assertApproxEqRel(_xerc20.mintingCurrentLimitOf(_user), _userLimit - 40 ether + (_userLimit / 2), 0.1 ether);

    assertApproxEqRel(_xerc20.burningCurrentLimitOf(_owner), _ownerLimit - 50 ether + (_ownerLimit / 2), 0.1 ether);
    assertApproxEqRel(_xerc20.burningCurrentLimitOf(_user), _userLimit - 25 ether + (_userLimit / 2), 0.1 ether);
  }
}
