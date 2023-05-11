import {CommonE2EBase} from './Common.sol';
import {XERC20Lockbox} from 'contracts/XERC20Lockbox.sol';
import {XERC20} from 'contracts/XERC20.sol';
import {XERC20Factory, IXERC20Factory} from 'contracts/XERC20Factory.sol';

contract E2EDeployment is CommonE2EBase {
  function testDeploy() public {
    assertEq(address(_xerc20.owner()), _owner);
    assertEq(_xerc20.name(), 'xDai Stablecoin');
    assertEq(_xerc20.symbol(), 'xDAI');
    assertEq(_xerc20.factory(), address(_xerc20Factory));
    assertEq(address(_lockbox.xerc20()), address(_xerc20));
    assertEq(address(_lockbox.erc20()), address(_dai));
    assertEq(_xerc20.getBurnerMaxLimit(_testMinter), 50 ether);
    assertEq(_xerc20.getMinterMaxLimit(_testMinter), 100 ether);
  }

  function testDeployLockbox() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    (address _token,) = _xerc20Factory.deploy('Test', 'TST', _limits, _limits, _minters, address(0));
    address _lock = _xerc20Factory.deployLockbox(_token, address(_dai));

    assertEq(address(XERC20Lockbox(_lock).xerc20()), address(_token));
    assertEq(address(XERC20Lockbox(_lock).erc20()), address(_dai));
  }
}
