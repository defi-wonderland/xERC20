// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {CommonE2EBase} from './Common.sol';
import {XERC20Lockbox} from '../../contracts/XERC20Lockbox.sol';
import {XERC20} from '../../contracts/XERC20.sol';
import {XERC20Factory, IXERC20Factory} from '../../contracts/XERC20Factory.sol';

contract E2EDeployment is CommonE2EBase {
  function testDeploy() public {
    assertEq(address(_xerc20.owner()), _owner);
    assertEq(_xerc20.name(), 'xDai Stablecoin');
    assertEq(_xerc20.symbol(), 'xDAI');
    assertEq(_xerc20.FACTORY(), address(_xerc20Factory));
    assertEq(address(_lockbox.XERC20()), address(_xerc20));
    assertEq(address(_lockbox.ERC20()), address(_dai));
    assertEq(_xerc20.burningMaxLimitOf(_testMinter), 50 ether);
    assertEq(_xerc20.mintingMaxLimitOf(_testMinter), 100 ether);
  }

  function testDeployLockbox() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    address _token = _xerc20Factory.deployXERC20('Test', 'TST', _limits, _limits, _minters);
    address _lock = _xerc20Factory.deployLockbox(_token, address(_dai), false);

    assertEq(address(XERC20Lockbox(payable(_lock)).XERC20()), address(_token));
    assertEq(address(XERC20Lockbox(payable(_lock)).ERC20()), address(_dai));
  }

  function testFactoryChaining() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    address _token = _oldFactory.deployXERC20('Test', 'TST', _limits, _limits, _minters);
    _oldFactory.deployLockbox(_token, address(_token), false);

    address[] memory _registeredTokens = _oldFactory.getRegisteredXERC20(0, 1);
    address[] memory _registeredLockboxes = _oldFactory.getRegisteredLockboxes(0, 1);

    assertEq(_registeredTokens.length, 1);
    assertEq(_registeredLockboxes.length, 1);
    assertEq(_xerc20Factory.isRegisteredXERC20(_registeredTokens[0]), true);
    assertEq(_xerc20Factory.isRegisteredLockbox(_registeredLockboxes[0]), true);
    assertEq(_xerc20Factory.lockboxRegistry(_registeredTokens[0]), _registeredLockboxes[0]);
  }
}
