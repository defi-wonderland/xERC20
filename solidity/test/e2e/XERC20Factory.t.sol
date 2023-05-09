import {CommonE2EBase} from './Common.sol';
import {XERC20Lockbox} from 'contracts/XERC20Lockbox.sol';
import {XERC20} from 'contracts/XERC20.sol';

contract E2EDeployment is CommonE2EBase {
  function testDeploy() public {
    uint256[] memory _limits = new uint256[](0);
    address[] memory _minters = new address[](0);

    (address _xerc20,) = _xerc20Factory.deploy('Test', 'TST', _limits, _minters, _limits, _minters, address(0));
    assertEq(XERC20(_xerc20).name(), 'xTest');
  }
}
