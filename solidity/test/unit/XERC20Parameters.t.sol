// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {XERC20Parameters} from 'contracts/XERC20Parameters.sol';
import {IXERC20Parameters} from 'interfaces/IXERC20Parameters.sol';

abstract contract Base is DSTestFull {
  address internal _owner = _label('_owner');
  address internal _minter = _label('_minter');
  XERC20Parameters internal _xerc20Parameters;

  event ParamsCreated(uint256[] _chainId, uint256[] _limits, address[] _minters);
  event LimitsChanged(uint256 _id, uint256 _oldLimit, uint256 _newLimit, address _minter);
  event ChainIdAdded(uint256 _id, uint256 _newChainId);

  function setUp() public virtual {
    vm.prank(_owner);
    _xerc20Parameters = new XERC20Parameters();
  }
}

contract UnitCreateParams is Base {
  function testCreateParam() public {
    uint256[] memory _chainId = new uint256[](0);
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.prank(_owner);
    _xerc20Parameters.createParams(_chainId, _limits, _minters);

    assertEq(_xerc20Parameters.balanceOf(_owner), 1);
  }

  function testChangeLimit(uint256 _amount, address _randomAddr) public {
    uint256[] memory _chainId = new uint256[](0);
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.startPrank(_owner);
    _xerc20Parameters.createParams(_chainId, _limits, _minters);

    _xerc20Parameters.changeLimit(1, _amount, _randomAddr);
    vm.stopPrank();
    assertEq(_xerc20Parameters.getLimits(1, _randomAddr), _amount);
  }

  function testAddChainId(uint256 _newChainId) public {
    uint256[] memory _chainId = new uint256[](0);
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.startPrank(_owner);
    _xerc20Parameters.createParams(_chainId, _limits, _minters);

    _xerc20Parameters.addChainId(1, _newChainId);
    vm.stopPrank();
    assertEq(_xerc20Parameters.getChainIdStatus(1, _newChainId), true);
  }

  function testBadChainIdIsFalse(uint256 _badChainId) public {
    uint256[] memory _chainId = new uint256[](0);
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.prank(_owner);
    _xerc20Parameters.createParams(_chainId, _limits, _minters);

    assertEq(_xerc20Parameters.getChainIdStatus(1, _badChainId), false);
  }

  function testCreationWithChainIds(uint256 _id1, uint256 _id2, uint256 _id3) public {
    uint256[] memory _chainId = new uint256[](3);
    _chainId[0] = _id1;
    _chainId[1] = _id2;
    _chainId[2] = _id3;

    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.prank(_owner);
    _xerc20Parameters.createParams(_chainId, _limits, _minters);

    assertEq(_xerc20Parameters.getChainIdStatus(1, _id1), true);
    assertEq(_xerc20Parameters.getChainIdStatus(1, _id2), true);
    assertEq(_xerc20Parameters.getChainIdStatus(1, _id3), true);
  }

  function testRevertsWithWrongCaller() public {
    uint256[] memory _chainId = new uint256[](0);

    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.prank(_owner);
    _xerc20Parameters.createParams(_chainId, _limits, _minters);

    vm.expectRevert(IXERC20Parameters.IXERC20Parameters_NotOwner.selector);
    _xerc20Parameters.addChainId(1, 100);
    vm.expectRevert(IXERC20Parameters.IXERC20Parameters_NotOwner.selector);
    _xerc20Parameters.changeLimit(1, 1e18, _minter);
  }

  function testAddingMintersAndLimits(
    uint256 _amount0,
    uint256 _amount1,
    uint256 _amount2,
    address _user0,
    address _user1,
    address _user2
  ) public {
    vm.assume(_user0 != _user1 && _user1 != _user2 && _user0 != _user2);
    uint256[] memory _chainId = new uint256[](0);
    uint256[] memory _limits = new uint256[](3);
    address[] memory _minters = new address[](3);

    _limits[0] = _amount0;
    _limits[1] = _amount1;
    _limits[2] = _amount2;

    _minters[0] = _user0;
    _minters[1] = _user1;
    _minters[2] = _user2;

    vm.prank(_owner);
    _xerc20Parameters.createParams(_chainId, _limits, _minters);

    assertEq(_xerc20Parameters.getLimits(1, _user0), _amount0);
    assertEq(_xerc20Parameters.getLimits(1, _user1), _amount1);
    assertEq(_xerc20Parameters.getLimits(1, _user2), _amount2);
  }

  function testCreateParamEmitsEvent() public {
    uint256[] memory _chainId = new uint256[](0);

    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.expectEmit(true, true, true, true);
    emit ParamsCreated(_chainId, _limits, _minters);
    vm.prank(_owner);
    _xerc20Parameters.createParams(_chainId, _limits, _minters);
  }

  function testAddChainIdEmitsEvent(uint256 _newChainId) public {
    uint256[] memory _chainId = new uint256[](0);

    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.startPrank(_owner);
    _xerc20Parameters.createParams(_chainId, _limits, _minters);
    vm.expectEmit(true, true, true, true);
    emit ChainIdAdded(1, _newChainId);
    _xerc20Parameters.addChainId(1, _newChainId);
  }

  function testChangeLimitEmitsEvent(uint256 _limit, address _minter) public {
    uint256[] memory _chainId = new uint256[](0);

    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.startPrank(_owner);
    _xerc20Parameters.createParams(_chainId, _limits, _minters);
    vm.expectEmit(true, true, true, true);
    emit LimitsChanged(1, 0, _limit, _minter);
    _xerc20Parameters.changeLimit(1, _limit, _minter);
  }
}
