// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {XERC20} from 'contracts/XERC20.sol';
import {XERC20Factory} from 'contracts/XERC20Factory.sol';
import {IXERC20Parameters} from 'contracts/XERC20Parameters.sol';
import {IXERC20} from 'interfaces/IXERC20.sol';
import {IXERC20Factory} from 'interfaces/IXERC20Factory.sol';

abstract contract Base is DSTestFull {
  address internal _owner = vm.addr(1);
  address internal _user = vm.addr(2);
  address internal _params = _mockContract('parameters');

  XERC20Factory internal _xerc20Factory;

  function setUp() public virtual {
    _xerc20Factory = new XERC20Factory(_params);
  }
}

contract UnitDeploy is Base {
  function testDeployment() public {
    vm.prank(address(_params));
    address _xerc20 = _xerc20Factory.deploy('Test', 'TST', 1);
    assertEq(XERC20(_xerc20).name(), 'xTest');
  }

  function testDeploymentReverts() public {
    vm.startPrank(address(_params));
    _xerc20Factory.deploy('Test', 'TST', 1);

    // should revert because Owner already deployed a contract with these params
    vm.expectRevert(IXERC20Factory.IXERC20Factory_AlreadyDeployed.selector);
    _xerc20Factory.deploy('Test', 'TST', 1);
    vm.stopPrank();
  }

  function testRevertsWhenAddressIsTaken() public {
    vm.prank(address(_params));
    _xerc20Factory.deploy('Test', 'TST', 1);

    vm.prank(address(_params));
    vm.expectRevert(IXERC20Factory.IXERC20Factory_AlreadyDeployed.selector);
    _xerc20Factory.deploy('Test', 'TST', 1);
  }

  function testComputedAddress() public {
    vm.startPrank(address(_params));
    bytes32 _salt = keccak256(abi.encodePacked('Test', 'TST', address(_params)));
    bytes memory _params = abi.encode('Test', 'TST', address(_params), 1);
    bytes32 _hash = keccak256(
      abi.encodePacked(
        bytes1(0xff), address(_xerc20Factory), _salt, keccak256(abi.encodePacked(type(XERC20).creationCode, _params))
      )
    );
    address _predictedAddress = address(uint160(uint256(_hash)));
    address _xerc20 = _xerc20Factory.deploy('Test', 'TST', 1);
    vm.stopPrank();

    assertEq(_predictedAddress, _xerc20);
  }

  function testWrongCallerReverts() public {
    vm.expectRevert(IXERC20Factory.IXERC20Factory_CantDeploy.selector);
    vm.prank(_owner);
    _xerc20Factory.deploy('Test', 'TST', 1);
  }
}
