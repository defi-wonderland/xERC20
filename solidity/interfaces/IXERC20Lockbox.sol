// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

interface IXERC20Lockbox {
  /**
   * @notice Emitted when tokens are deposited into the lockbox
   */

  event Deposit(address _sender, uint256 _amount);

  /**
   * @notice Emitted when tokens are withdrawn from the lockbox
   */

  event Withdraw(address _sender, uint256 _amount);
  /**
   * @notice Deposit ERC20 tokens into the lockbox
   *
   * @param _amount The amount of tokens to deposit
   */

  function deposit(uint256 _amount) external;

  /**
   * @notice Withdraw ERC20 tokens from the lockbox
   *
   * @param _amount The amount of tokens to withdraw
   */

  function withdraw(uint256 _amount) external;
}
