// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {XERC20} from 'contracts/XERC20.sol';
import {XERC20Factory} from 'contracts/XERC20Factory.sol';
import {IXERC20} from 'interfaces/IXERC20.sol';
import {IXERC20Factory} from 'interfaces/IXERC20Factory.sol';

abstract contract Base is Test {
  address internal _owner = vm.addr(1);
  address internal _user = vm.addr(2);
  XERC20Factory internal _xerc20Factory;

  function setUp() public virtual {
    vm.prank(_owner);
    _xerc20Factory = new XERC20Factory();
  }
}

contract UnitDeploy is Base {
  function testDeployment() public {
    address _xerc20 = _xerc20Factory.deploy('Test', 'TST');
    assertEq(XERC20(_xerc20).name(), 'xTest');
  }

  function testDeploymentReverts() public {
    vm.startPrank(_owner);
    _xerc20Factory.deploy('Test', 'TST');

    // should revert because Owner already deployed a contract with these params
    vm.expectRevert(IXERC20Factory.IXERC20Factory_AlreadyDeployed.selector);
    _xerc20Factory.deploy('Test', 'TST');
    vm.stopPrank();
  }

  function testDifferentCallersDeployWithSameNames() public {
    vm.prank(_owner);
    address _token0 = _xerc20Factory.deploy('Test', 'TST');

    vm.prank(_user);
    address _token1 = _xerc20Factory.deploy('Test', 'TST');

    assertEq(XERC20(_token0).name(), 'xTest');
    assertEq(XERC20(_token1).name(), 'xTest');
  }

  function testComputedAddress() public {
    vm.startPrank(_owner);
    bytes32 _salt = keccak256(abi.encodePacked('Test', 'TST', _owner));
    bytes memory _params = abi.encode('Test', 'TST');
    bytes32 _hash = keccak256(
      abi.encodePacked(
        bytes1(0xff), address(_xerc20Factory), _salt, keccak256(abi.encodePacked(type(XERC20).creationCode, _params))
      )
    );
    address _predictedAddress = address(uint160(uint256(_hash)));
    address _xerc20 = _xerc20Factory.deploy('Test', 'TST');
    vm.stopPrank();

    assertEq(_predictedAddress, _xerc20);
  }
}
