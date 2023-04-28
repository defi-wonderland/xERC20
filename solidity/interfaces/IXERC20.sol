// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

interface IXERC20 {
  /**
   * @notice Emitted when a new minter is added
   */

  event AddedMinter(address _minter);

  /**
   * @notice Emitted when a minter is removed
   */

  event RemovedMinter(address _minter);

  /**
   * @notice Reverts when a non minter tries to call a minter only function
   */

  error OnlyMinters();

  /**
   * @notice Adds a minter to the allowlist
   *
   * @param _minter The address of the minter to give permissions to
   */

  function setMinter(address _minter) external;

  /**
   * @notice Removes a minter from the allowlist
   *
   * @param _minter The address of the minter to give permissions to
   */

  function removeMinter(address _minter) external;

  /**
   * @notice Mints tokens for a user
   * @dev Can only be called by a minter
   * @param _user The address of the user who needs tokens minted
   * @param _amount The amount of tokens being minted
   */

  function mint(address _user, uint256 _amount) external;

  /**
   * @notice Burns tokens for a user
   * @dev Can only be called by a minter
   * @param _user The address of the user who needs tokens burned
   * @param _amount The amount of tokens being burned
   */

  function burn(address _user, uint256 _amount) external;
}
