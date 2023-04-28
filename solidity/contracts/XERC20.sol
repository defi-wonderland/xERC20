// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {IXERC20} from 'interfaces/IXERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract XERC20 is ERC20, Ownable, IXERC20 {
  mapping(address => bool) public minters;

  /**
   * @notice Constructs the initial config of the XERC20
   *
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   */

  constructor(string memory _name, string memory _symbol) ERC20(string.concat('x', _name), string.concat('x', _symbol)) {}

  /**
   * @notice Adds a minter to the allowlist
   * @dev Can only be called by the owner
   * @param _minter The address of the minter to give permissions to
   */

  function setMinter(address _minter) external onlyOwner {
    minters[_minter] = true;
  }
}
