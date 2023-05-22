// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {IXERC20} from 'interfaces/IXERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IXERC20Lockbox} from 'interfaces/IXERC20Lockbox.sol';

contract XERC20Lockbox is IXERC20Lockbox {
  using SafeERC20 for IERC20;

  IXERC20 public immutable XERC20;
  IERC20 public immutable ERC20;

  /**
   * @notice Constructor
   *
   * @param _xerc20 The address of the XERC20 contract
   * @param _erc20 The address of the ERC20 contract
   */

  constructor(address _xerc20, address _erc20) {
    XERC20 = IXERC20(_xerc20);
    ERC20 = IERC20(_erc20);
  }

  /**
   * @notice Deposit ERC20 tokens into the lockbox
   *
   * @param _amount The amount of tokens to deposit
   */

  function deposit(uint256 _amount) external {
    ERC20.safeTransferFrom(msg.sender, address(this), _amount);
    XERC20.mint(msg.sender, _amount);

    emit DepositedERC20(msg.sender, _amount);
  }

  /**
   * @notice Withdraw ERC20 tokens from the lockbox
   *
   * @param _amount The amount of tokens to withdraw
   */

  function withdraw(uint256 _amount) external {
    ERC20.safeTransfer(msg.sender, _amount);
    XERC20.burn(msg.sender, _amount);

    emit WithdrawnERC20(msg.sender, _amount);
  }
}
