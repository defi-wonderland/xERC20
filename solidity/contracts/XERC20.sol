// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {IXERC20} from 'interfaces/IXERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {ERC20Permit} from '@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IXERC20Parameters} from 'interfaces/IXERC20Parameters.sol';

contract XERC20 is ERC20, Ownable, IXERC20, ERC20Permit {
  IXERC20Parameters public immutable PARAMETERS;
  uint256 public id;
  address public factory;

  /**
   * @notice Constructs the initial config of the XERC20
   *
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   * @param _parameters The address of the parameter contract for this XERC20
   * @param _id The id of the NFT that manages the parameters
   */

  constructor(
    string memory _name,
    string memory _symbol,
    address _parameters,
    uint256 _id
  ) ERC20(string.concat('x', _name), string.concat('x', _symbol)) ERC20Permit(string.concat('x', _name)) {
    PARAMETERS = IXERC20Parameters(_parameters);
    id = _id;
  }

  /**
   * @notice Mints tokens for a user
   * @dev Can only be called by a minter
   * @param _user The address of the user who needs tokens minted
   * @param _amount The amount of tokens being minted
   */

  function mint(address _user, uint256 _amount) external {
    if (!PARAMETERS.isMinterApproved(id, _user)) revert IXERC20_NotApprovedMinter();
    _mint(_user, _amount);
  }

  /**
   * @notice Burns tokens for a user
   * @dev Can only be called by a minter
   * @param _user The address of the user who needs tokens burned
   * @param _amount The amount of tokens being burned
   */

  function burn(address _user, uint256 _amount) external {
    uint256 _currentLimit = PARAMETERS.getMaxLimit(id, _user);
    if (_currentLimit < _amount) revert IXERC20_NotHighEnoughLimits();
    PARAMETERS.useLimits(id, _amount, _user);
    _burn(_user, _amount);
  }
}
