// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {IXERC20} from 'interfaces/IXERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {ERC20Permit} from '@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract XERC20 is ERC20, Ownable, IXERC20, ERC20Permit {
  mapping(address => bool) public minters;

  /**
   * @notice Constructs the initial config of the XERC20
   *
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   */

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC20(string.concat('x', _name), string.concat('x', _symbol)) ERC20Permit(string.concat('x', _name)) {}

  /**
   * @notice Adds a minter to the allowlist
   * @dev Can only be called by the owner
   * @param _minter The address of the minter to give permissions to
   */

  function setMinter(address _minter) external onlyOwner {
    minters[_minter] = true;

    emit AddedMinter(_minter);
  }

  /**
   * @notice Removes a minter from the allowlist
   * @dev Can only be called by the owner
   * @param _minter The address of the minter to give permissions to
   */

  function removeMinter(address _minter) external onlyOwner {
    minters[_minter] = false;

    emit RemovedMinter(_minter);
  }

  /**
   * @notice Mints tokens for a user
   * @dev Can only be called by a minter
   * @param _user The address of the user who needs tokens minted
   * @param _amount The amount of tokens being minted
   */

  function mint(address _user, uint256 _amount) external {
    if (!minters[msg.sender]) revert OnlyMinters();
    _mint(_user, _amount);
  }

  /**
   * @notice Burns tokens for a user
   * @dev Can only be called by a minter
   * @param _user The address of the user who needs tokens burned
   * @param _amount The amount of tokens being burned
   */

  function burn(address _user, uint256 _amount) external {
    if (!minters[msg.sender]) revert OnlyMinters();
    _burn(_user, _amount);
  }
}
