// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {XERC20} from 'contracts/XERC20.sol';
import {IXERC20Parameters} from 'interfaces/IXERC20Parameters.sol';
import {IXERC20Factory} from 'interfaces/IXERC20Factory.sol';
import {IXERC20} from 'interfaces/IXERC20.sol';

abstract contract Base is DSTestFull {
  address internal _owner = _label('owner');
  address internal _user = _label('user');
  address internal _factory = _mockContract('factory');
  address internal _parameters = _mockContract('parameters');

  XERC20 internal _xerc20;

  function setUp() public virtual {
    vm.startPrank(_owner);
    _xerc20 = new XERC20('Test', 'TST', _parameters, 1);
    vm.stopPrank();

    vm.mockCall(
      address(_parameters), abi.encodeWithSelector(IXERC20Parameters.isMinterApproved.selector), abi.encode(true)
    );
  }
}

contract UnitNames is Base {
  function testName() public {
    assertEq('xTest', _xerc20.name());
  }

  function testSymbol() public {
    assertEq('xTST', _xerc20.symbol());
  }
}

contract UnitMintBurn is Base {
  function testMintRevertsIfNotApprove(uint256 _amount) public {
    vm.mockCall(
      address(_parameters), abi.encodeWithSelector(IXERC20Parameters.isMinterApproved.selector), abi.encode(false)
    );
    vm.prank(_user);
    vm.expectRevert(IXERC20.IXERC20_NotApprovedMinter.selector);
    _xerc20.mint(_user, _amount);
  }

  function testBurnRevertsWhenLimitIsTooLow(uint256 _amount0, uint256 _amount1) public {
    vm.assume(_amount1 > _amount0);
    vm.mockCall(
      address(_parameters), abi.encodeWithSelector(IXERC20Parameters.getMaxLimit.selector), abi.encode(_amount0)
    );

    vm.startPrank(_user);
    _xerc20.mint(_user, _amount1);
    vm.expectRevert(IXERC20.IXERC20_NotHighEnoughLimits.selector);
    _xerc20.burn(_user, _amount1);
    vm.stopPrank();
  }

  function testMint(uint256 _amount) public {
    vm.prank(_user);
    vm.expectCall(_parameters, abi.encodeCall(IXERC20Parameters(_parameters).isMinterApproved, (1, _user)));
    _xerc20.mint(_user, _amount);

    assertEq(_xerc20.balanceOf(_user), _amount);
  }

  function testBurn(uint256 _amount) public {
    vm.mockCall(
      address(_parameters), abi.encodeWithSelector(IXERC20Parameters.getMaxLimit.selector), abi.encode(_amount)
    );

    vm.startPrank(_user);
    _xerc20.mint(_user, _amount);
    vm.expectCall(_parameters, abi.encodeCall(IXERC20Parameters(_parameters).getMaxLimit, (1, _user)));
    vm.expectCall(_parameters, abi.encodeCall(IXERC20Parameters(_parameters).useLimits, (1, _amount, _user)));
    _xerc20.burn(_user, _amount);
    vm.stopPrank();

    assertEq(_xerc20.balanceOf(_user), 0);
  }

  function testCanStillMintWhenLimitIsReached(uint256 _amount) public {
    vm.mockCall(
      address(_parameters), abi.encodeWithSelector(IXERC20Parameters.getMaxLimit.selector), abi.encode(_amount)
    );
    vm.assume(_amount <= 10_000);

    vm.startPrank(_user);
    _xerc20.mint(_user, _amount);
    _xerc20.burn(_user, _amount);

    _xerc20.mint(_user, _amount);
    vm.stopPrank();

    assertEq(_xerc20.balanceOf(_user), _amount);
  }
}
