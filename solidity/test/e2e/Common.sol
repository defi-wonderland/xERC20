// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';
import {Test} from 'forge-std/Test.sol';
import {XERC20} from '../../contracts/XERC20.sol';
import {XERC20Lockbox} from '../../contracts/XERC20Lockbox.sol';

import {XERC20Factory} from '../../contracts/XERC20Factory.sol';

contract CommonE2EBase is Test {
  uint256 internal constant _FORK_BLOCK = 18_213_198;
  uint256 internal _userPrivateKey = 0x1234;
  address internal _user = vm.addr(_userPrivateKey);
  address internal _owner = vm.addr(200);
  address internal _multicall = vm.addr(300);
  address internal _testMinter = vm.addr(123_456_789);

  IERC20 internal _dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  XERC20 internal _xerc20;
  XERC20Lockbox internal _lockbox;
  XERC20Factory internal _xerc20Factory;

  function setUp() public virtual {
    vm.createSelectFork(vm.rpcUrl(vm.envString('MAINNET_RPC')), _FORK_BLOCK);
    uint256[] memory _minterLimits = new uint256[](1);
    uint256[] memory _burnerLimits = new uint256[](1);
    address[] memory _bridges = new address[](1);

    _bridges[0] = _testMinter;
    _minterLimits[0] = 100 ether;
    _burnerLimits[0] = 50 ether;

    vm.startPrank(_owner);
    _xerc20Factory = new XERC20Factory();
    address _token = _xerc20Factory.deployXERC20(_dai.name(), _dai.symbol(), _minterLimits, _burnerLimits, _bridges);
    address payable _lock = _xerc20Factory.deployLockbox(_token, address(_dai), false);

    _xerc20 = XERC20(_token);
    _lockbox = XERC20Lockbox(_lock);
    vm.stopPrank();
  }
}
