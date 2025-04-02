// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {DSTestFull} from '../../test/utils/DSTestFull.sol';
import {XERC20} from '../../contracts/XERC20.sol';
import {XERC20Factory} from '../../contracts/XERC20Factory.sol';
import {XERC20Lockbox} from '../../contracts/XERC20Lockbox.sol';
import {IXERC20Factory} from '../../interfaces/IXERC20Factory.sol';
import {IXERC20Lockbox} from '../../interfaces/IXERC20Lockbox.sol';
import {CREATE3} from 'solady/utils/CREATE3.sol';

contract XERC20FactoryForTest is XERC20Factory {
  function getDeployed(
    bytes32 _salt
  ) public view returns (address _precomputedAddress) {
    _precomputedAddress = CREATE3.predictDeterministicAddress(_salt);
  }
}

abstract contract Base is DSTestFull {
  address internal _owner = vm.addr(1);
  address internal _user = vm.addr(2);
  address internal _erc20 = vm.addr(3);

  XERC20FactoryForTest internal _xerc20Factory;

  event XERC20Deployed(address _xerc20);
  event LockboxDeployed(address payable _lockbox);

  function setUp() public virtual {
    _xerc20Factory = new XERC20FactoryForTest();
  }
}

contract UnitDeploy is Base {
  function testDeployment() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    XERC20 _xerc20 = XERC20(_xerc20Factory.deployXERC20('Test', 'TST', 18, _owner, _limits, _limits, _minters));
    assertEq(_xerc20.name(), 'Test');
    assertEq(_xerc20.symbol(), 'TST');
    assertEq(_xerc20.FACTORY(), address(_xerc20Factory));
  }

  function testDeploymentWithLimitsAndMinters() public {
    uint256[] memory _limits = new uint256[](1);
    address[] memory _minters = new address[](1);

    _limits[0] = 1e18;
    _minters[0] = _user;

    XERC20 _xerc20 = XERC20(_xerc20Factory.deployXERC20('Test', 'TST', 18, _owner, _limits, _limits, _minters));
    assertEq(_xerc20.name(), 'Test');
    assertEq(_xerc20.symbol(), 'TST');
    assertEq(_xerc20.FACTORY(), address(_xerc20Factory));
  }

  function testRevertsWhenAddressIsTaken() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.prank(_owner);
    _xerc20Factory.deployXERC20('Test', 'TST', 18, _owner, _limits, _limits, _minters);

    vm.prank(_owner);
    vm.expectRevert(CREATE3.DeploymentFailed.selector);
    _xerc20Factory.deployXERC20('Test', 'TST', 18, _owner, _limits, _limits, _minters);
  }

  function testComputedAddress() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.startPrank(address(_owner));
    bytes32 _salt = keccak256(abi.encode('Test', 'TST', uint8(18), _owner));

    address _xerc20 = _xerc20Factory.deployXERC20('Test', 'TST', 18, _owner, _limits, _limits, _minters);
    vm.stopPrank();
    address _predictedAddress = _xerc20Factory.getDeployed(_salt);

    assertEq(_predictedAddress, _xerc20);
  }

  function testLockboxPrecomputedAddress() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.startPrank(_owner);
    vm.mockCall(address(_erc20), abi.encodeWithSignature('decimals()'), abi.encode(18));
    (address _xerc20, address payable _lockbox) =
      _xerc20Factory.deployXERC20WithLockbox('Test', 'TST', _owner, _limits, _limits, _minters, _erc20, false);

    vm.stopPrank();

    bytes32 _salt = keccak256(abi.encode(_xerc20, _erc20, _owner));
    address _predictedAddress = _xerc20Factory.getDeployed(_salt);

    assertEq(_predictedAddress, _lockbox);
  }

  function testLockboxSingleDeployment() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.startPrank(_owner);
    vm.mockCall(address(_erc20), abi.encodeWithSignature('decimals()'), abi.encode(18));
    (address _xerc20, address payable _lockbox) =
      _xerc20Factory.deployXERC20WithLockbox('Test', 'TST', _owner, _limits, _limits, _minters, _erc20, false);
    vm.stopPrank();

    assertEq(address(XERC20Lockbox(_lockbox).XERC20()), _xerc20);
    assertEq(address(XERC20Lockbox(_lockbox).BASE_TOKEN()), _erc20);
  }

  function testLockboxDeploymentRevertsIfMaliciousAddress() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    // Malicious address does not implement decimals() will return EvmError: Revert.
    vm.expectRevert();
    _xerc20Factory.deployXERC20WithLockbox('Test', 'TST', _owner, _limits, _limits, _minters, address(0), false);
  }

  function testLockboxDeploymentRevertsIfInvalidParameters() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);
    vm.expectRevert(CREATE3.DeploymentFailed.selector);
    _xerc20Factory.deployXERC20WithLockbox('Test', 'TST', _owner, _limits, _limits, _minters, address(100), true);
  }

  function testNotParallelArraysRevert() public {
    uint256[] memory _minterLimits = new uint256[](1);
    uint256[] memory _burnerLimits = new uint256[](1);
    uint256[] memory _empty = new uint256[](0);
    address[] memory _minters = new address[](0);

    _minterLimits[0] = 1;
    _burnerLimits[0] = 1;

    vm.prank(_owner);
    vm.expectRevert(IXERC20Factory.IXERC20Factory_InvalidLength.selector);
    _xerc20Factory.deployXERC20('Test', 'TST', 18, _owner, _minterLimits, _empty, _minters);

    vm.expectRevert(IXERC20Factory.IXERC20Factory_InvalidLength.selector);
    _xerc20Factory.deployXERC20('Test', 'TST', 18, _owner, _empty, _burnerLimits, _minters);
  }

  function testDeployEmitsEvent() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    address _token = _xerc20Factory.getDeployed(keccak256(abi.encode('Test', 'TST', uint8(18), _owner)));
    vm.expectEmit(true, true, true, true);
    emit XERC20Deployed(_token);
    vm.prank(_owner);
    _xerc20Factory.deployXERC20('Test', 'TST', 18, _owner, _limits, _limits, _minters);
  }

  function testLockboxEmitsEvent() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    address _xerc20 = _xerc20Factory.getDeployed(keccak256(abi.encode('Test', 'TST', uint8(18), _owner)));

    address payable _lockbox = payable(_xerc20Factory.getDeployed(keccak256(abi.encode(_xerc20, _erc20, _owner))));

    vm.prank(_owner);
    vm.mockCall(address(_erc20), abi.encodeWithSignature('decimals()'), abi.encode(18));
    vm.expectEmit(true, true, true, true);
    emit LockboxDeployed(_lockbox);
    _xerc20Factory.deployXERC20WithLockbox('Test', 'TST', _owner, _limits, _limits, _minters, _erc20, false);
  }
}
