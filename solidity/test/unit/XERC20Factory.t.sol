// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {XERC20} from 'contracts/XERC20.sol';
import {XERC20Factory} from 'contracts/XERC20Factory.sol';
import {IXERC20} from 'interfaces/IXERC20.sol';
import {IXERC20Factory} from 'interfaces/IXERC20Factory.sol';

abstract contract Base is DSTestFull {
  address internal _owner = vm.addr(1);
  address internal _user = vm.addr(2);

  XERC20Factory internal _xerc20Factory;

  function setUp() public virtual {
    _xerc20Factory = new XERC20Factory();
  }
}

contract UnitDeploy is Base {
  function testDeployment() public {
    uint256[] memory _chainId = new uint256[](0);
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    address _xerc20 = _xerc20Factory.deploy('Test', 'TST', _limits, _minters, _chainId);
    assertEq(XERC20(_xerc20).name(), 'xTest');
  }

  function testRevertsWhenAddressIsTaken() public {
    uint256[] memory _chainId = new uint256[](0);
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.prank(_owner);
    _xerc20Factory.deploy('Test', 'TST', _limits, _minters, _chainId);

    vm.prank(_owner);
    vm.expectRevert(IXERC20Factory.IXERC20Factory_AlreadyDeployed.selector);
    _xerc20Factory.deploy('Test', 'TST', _limits, _minters, _chainId);
  }

  function testComputedAddress() public {
    uint256[] memory _chainId = new uint256[](0);
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    vm.startPrank(address(_owner));
    bytes32 _salt = keccak256(abi.encodePacked('Test', 'TST', _owner));
    bytes memory _params = abi.encode('Test', 'TST');
    bytes32 _hash = keccak256(
      abi.encodePacked(
        bytes1(0xff), address(_xerc20Factory), _salt, keccak256(abi.encodePacked(type(XERC20).creationCode, _params))
      )
    );
    address _predictedAddress = address(uint160(uint256(_hash)));
    address _xerc20 = _xerc20Factory.deploy('Test', 'TST', _limits, _minters, _chainId);
    vm.stopPrank();

    assertEq(_predictedAddress, _xerc20);
  }

  function testRegistryIsStoredCorrectly() public {
    uint256[] memory _chainId = new uint256[](0);
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);
    address _xerc20 = _xerc20Factory.deploy('Test', 'TST', _limits, _minters, _chainId);

    assertEq(_xerc20Factory.registry(_xerc20), true);
    assertEq(_xerc20Factory.registryArray(0), _xerc20);
  }
}
