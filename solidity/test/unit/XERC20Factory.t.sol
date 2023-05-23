// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {XERC20} from 'contracts/XERC20.sol';
import {XERC20Factory} from 'contracts/XERC20Factory.sol';
import {XERC20Lockbox} from 'contracts/XERC20Lockbox.sol';
import {IXERC20} from 'interfaces/IXERC20.sol';
import {IXERC20Factory} from 'interfaces/IXERC20Factory.sol';
import {CREATE3} from 'isolmate/utils/CREATE3.sol';

contract XERC20FactoryForTest is XERC20Factory {
  function getDeployed(bytes32 _salt) public view returns (address _precomputedAddress) {
    _precomputedAddress = CREATE3.getDeployed(_salt);
  }
}

abstract contract Base is DSTestFull {
  address internal _owner = vm.addr(1);
  address internal _user = vm.addr(2);
  address internal _erc20 = vm.addr(3);

  XERC20FactoryForTest internal _xerc20Factory;

  event XERC20Deployed(address _xerc20, address _lockbox);
  event LockboxDeployed(address _lockbox);

  function setUp() public virtual {
    _xerc20Factory = new XERC20FactoryForTest();
  }
}

contract UnitDeploy is Base {
  function testDeployment() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    (address _xerc20,) = _xerc20Factory.deploy('Test', 'TST', _limits, _limits, _minters, address(0));
    assertEq(XERC20(_xerc20).name(), 'xTest');
  }

  function testRevertsWhenAddressIsTaken() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.prank(_owner);
    _xerc20Factory.deploy('Test', 'TST', _limits, _limits, _minters, address(0));

    vm.prank(_owner);
    vm.expectRevert('DEPLOYMENT_FAILED');
    _xerc20Factory.deploy('Test', 'TST', _limits, _limits, _minters, address(0));
  }

  function testComputedAddress() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.startPrank(address(_owner));
    bytes32 _salt = keccak256(abi.encodePacked('Test', 'TST', _owner));

    (address _xerc20,) = _xerc20Factory.deploy('Test', 'TST', _limits, _limits, _minters, address(0));
    vm.stopPrank();
    address _predictedAddress = _xerc20Factory.getDeployed(_salt);

    assertEq(_predictedAddress, _xerc20);
  }

  function testDeploymentWithLockbox() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    (address _xerc20,) = _xerc20Factory.deploy('Test', 'TST', _limits, _limits, _minters, _erc20);
    address _lockbox = _xerc20Factory.lockboxRegistry(_xerc20);

    assertEq(address(XERC20Lockbox(_lockbox).XERC20()), address(_xerc20));
    assertEq(address(XERC20Lockbox(_lockbox).ERC20()), _erc20);
  }

  function testLockboxPrecomputedAddress() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.prank(_owner);
    (address _xerc20,) = _xerc20Factory.deploy('Test', 'TST', _limits, _limits, _minters, _erc20);
    address _lockbox = _xerc20Factory.lockboxRegistry(_xerc20);

    bytes32 _salt = keccak256(abi.encodePacked(_xerc20, _erc20, _owner));
    address _predictedAddress = _xerc20Factory.getDeployed(_salt);

    assertEq(_predictedAddress, _lockbox);
  }

  function testLockboxStorageWorks() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.prank(_owner);
    (address _xerc20,) = _xerc20Factory.deploy('Test', 'TST', _limits, _limits, _minters, _erc20);
    bytes32 _salt = keccak256(abi.encodePacked(_xerc20, _erc20, _owner));

    assertEq(_xerc20Factory.lockboxRegistry(_xerc20), _xerc20Factory.getDeployed(_salt));
  }

  function testLockboxDoesntDeployWithBadParams() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.startPrank(_owner);
    (address _token0,) = _xerc20Factory.deploy('Test', 'TST', _limits, _limits, _minters, address(0));
    vm.stopPrank();

    assertEq(_xerc20Factory.lockboxRegistry(_token0), address(0));
  }

  function testLockboxSingleDeployment() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.startPrank(_owner);
    (address _xerc20,) = _xerc20Factory.deploy('Test', 'TST', _limits, _limits, _minters, address(0));

    address _lockbox = _xerc20Factory.deployLockbox(_xerc20, _erc20);
    vm.stopPrank();

    assertEq(address(XERC20Lockbox(_lockbox).XERC20()), _xerc20);
    assertEq(address(XERC20Lockbox(_lockbox).ERC20()), _erc20);
  }

  function testLockboxSingleDeploymentRevertsIfNotOwner() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.startPrank(_owner);
    (address _xerc20,) = _xerc20Factory.deploy('Test', 'TST', _limits, _limits, _minters, address(0));
    vm.stopPrank();

    vm.expectRevert(IXERC20Factory.IXERC20Factory_NotOwner.selector);
    _xerc20Factory.deployLockbox(_xerc20, _erc20);
  }

  function testLockboxDeploymentRevertsIfMaliciousAddress() public {
    vm.expectRevert(IXERC20Factory.IXERC20Factory_BadTokenAddress.selector);
    _xerc20Factory.deployLockbox(address(0), _erc20);

    vm.expectRevert(IXERC20Factory.IXERC20Factory_BadTokenAddress.selector);
    _xerc20Factory.deployLockbox(_erc20, address(0));

    vm.expectRevert(IXERC20Factory.IXERC20Factory_BadTokenAddress.selector);
    _xerc20Factory.deployLockbox(address(111), _erc20);
  }

  function testCantDeployLockboxTwice() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    (address _xerc20,) = _xerc20Factory.deploy('Test', 'TST', _limits, _limits, _minters, _erc20);

    vm.expectRevert(IXERC20Factory.IXERC20Factory_LockboxAlreadyDeployed.selector);
    _xerc20Factory.deployLockbox(_xerc20, _erc20);
  }

  function testNotParallelArraysRevert() public {
    uint256[] memory _minterLimits = new uint256[](1);
    uint256[] memory _burnerLimits = new uint256[](1);
    uint256[] memory _empty = new uint256[](0);
    address[] memory _minters = new address[](0);

    _minterLimits[0] = 1;
    _burnerLimits[0] = 1;

    vm.prank(_owner);
    vm.expectRevert(IXERC20.IXERC20_IncompatibleLengths.selector);
    _xerc20Factory.deploy('Test', 'TST', _minterLimits, _empty, _minters, _erc20);

    vm.expectRevert(IXERC20.IXERC20_IncompatibleLengths.selector);
    _xerc20Factory.deploy('Test', 'TST', _empty, _burnerLimits, _minters, _erc20);
  }

  function testRegisteredXerc20ArraysAreStored() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    (address _xerc1,) = _xerc20Factory.deploy('_xerc1', '_xerc1', _limits, _limits, _minters, _erc20);
    (address _xerc2,) = _xerc20Factory.deploy('_xerc2', '_xerc2', _limits, _limits, _minters, _erc20);
    (address _xerc3,) = _xerc20Factory.deploy('_xerc3', '_xerc3', _limits, _limits, _minters, _erc20);

    address[] memory _xercs = _xerc20Factory.getRegisteredXERC20(0, 5);

    assertEq(_xercs.length, 3);

    assertEq(_xercs[0], _xerc1);
    assertEq(_xercs[1], _xerc2);
    assertEq(_xercs[2], _xerc3);
  }

  function testRegisteredLockboxArraysAreStored() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    (, address _lockbox1) = _xerc20Factory.deploy('_xerc1', '_xerc1', _limits, _limits, _minters, _erc20);
    (, address _lockbox2) = _xerc20Factory.deploy('_xerc2', '_xerc2', _limits, _limits, _minters, _erc20);
    (, address _lockbox3) = _xerc20Factory.deploy('_xerc3', '_xerc3', _limits, _limits, _minters, _erc20);

    address[] memory _lockboxes = _xerc20Factory.getRegisteredLockboxes(0, 5);

    assertEq(_lockboxes.length, 3);

    assertEq(_lockboxes[0], _lockbox1);
    assertEq(_lockboxes[1], _lockbox2);
    assertEq(_lockboxes[2], _lockbox3);
  }

  function testIsXERC20(address _randomAddr) public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    (address _token,) = _xerc20Factory.deploy('Test', 'TST', _limits, _limits, _minters, address(0));
    vm.assume(_randomAddr != _token);
    assertEq(_xerc20Factory.isXERC20(_randomAddr), false);
    assertEq(_xerc20Factory.isXERC20(_token), true);
  }

  function testGetMiddleOfRegisteredLockboxArrays() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    _xerc20Factory.deploy('_xerc1', '_xerc1', _limits, _limits, _minters, _erc20);
    (, address _lockbox2) = _xerc20Factory.deploy('_xerc2', '_xerc2', _limits, _limits, _minters, _erc20);
    (, address _lockbox3) = _xerc20Factory.deploy('_xerc3', '_xerc3', _limits, _limits, _minters, _erc20);

    address[] memory _lockboxes = _xerc20Factory.getRegisteredLockboxes(1, 2);

    assertEq(_lockboxes.length, 2);

    assertEq(_lockboxes[0], _lockbox2);
    assertEq(_lockboxes[1], _lockbox3);
  }

  function testGetMiddleOfRegisteredXERC20s() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    _xerc20Factory.deploy('_xerc1', '_xerc1', _limits, _limits, _minters, _erc20);
    (address _xerc2,) = _xerc20Factory.deploy('_xerc2', '_xerc2', _limits, _limits, _minters, _erc20);
    (address _xerc3,) = _xerc20Factory.deploy('_xerc3', '_xerc3', _limits, _limits, _minters, _erc20);

    address[] memory _xercs = _xerc20Factory.getRegisteredXERC20(1, 2);

    assertEq(_xercs.length, 2);

    assertEq(_xercs[0], _xerc2);
    assertEq(_xercs[1], _xerc3);
  }

  function testDeployEmitsEvent() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    address _token = _xerc20Factory.getDeployed(keccak256(abi.encodePacked('Test', 'TST', _owner)));
    address _lockbox = _xerc20Factory.getDeployed(keccak256(abi.encodePacked(_token, _erc20, _owner)));
    vm.expectEmit(true, true, true, true);
    emit XERC20Deployed(_token, _lockbox);
    vm.prank(_owner);
    _xerc20Factory.deploy('Test', 'TST', _limits, _limits, _minters, _erc20);
  }

  function testLockboxEmitsEvent() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);
    vm.prank(_owner);
    (address _token,) = _xerc20Factory.deploy('Test', 'TST', _limits, _limits, _minters, address(0));
    address _lockbox = _xerc20Factory.getDeployed(keccak256(abi.encodePacked(_token, _erc20, _owner)));

    vm.expectEmit(true, true, true, true);
    emit LockboxDeployed(_lockbox);
    vm.prank(_owner);
    _xerc20Factory.deployLockbox(_token, _erc20);
  }
}
