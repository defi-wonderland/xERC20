// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

interface IXERC20Factory {
  /**
   * @notice Emitted when a new XERC20 is deployed
   */

  event XERC20Deployed(address _xerc20);

  /**
   * @notice Emitted when a new XERC20Lockbox is deployed
   */

  event LockboxDeployed(address _lockbox);

  /**
   * @notice Reverts when a non-owner attempts to call
   */

  error IXERC20Factory_NotOwner();

  /**
   * @notice Reverts when a lockbox is trying to be deployed from a malicious address
   */

  error IXERC20Factory_BadTokenAddress();

  /**
   * @notice Reverts when a lockbox is already deployed
   */

  error IXERC20Factory_LockboxAlreadyDeployed();

  /**
   * @notice Reverts when a the length of arrays sent is incorrect
   */
  error IXERC20Factory_InvalidLength();

  /**
   * @notice Deploys an XERC20 contract using CREATE3
   * @dev _limits and _minters must be the same length
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   * @param _burnerLimits The array of limits that you are adding (optional, can be an empty array)
   * @param _bridges The array of burners that you are adding (optional, can be an empty array)
   */

  function deployXERC20(
    string memory _name,
    string memory _symbol,
    uint256[] memory _minterLimits,
    uint256[] memory _burnerLimits,
    address[] memory _bridges
  ) external returns (address _xerc20);

  /**
   * @notice Deploys an XERC20Lockbox contract using CREATE3
   *
   * @param _xerc20 The address of the xerc20 that you want to deploy a lockbox for
   * @param _baseToken The address of the base token that you want to lock
   * @param _isNative Whether or not the base token is native
   */

  function deployLockbox(
    address _xerc20,
    address _baseToken,
    bool _isNative
  ) external returns (address payable _lockbox);

  /**
   * @notice Loops through the xerc20RegistryArray
   *
   * @param _start The start of the loop
   * @param _amount The end of the loop
   * @return _lockboxes The array of xerc20s from the start to start + amount
   */

  function getRegisteredLockboxes(uint256 _start, uint256 _amount) external view returns (address[] memory _lockboxes);

  /**
   * @notice Loops through the xerc20RegistryArray
   *
   * @param _start The start of the loop
   * @param _amount The amount of xerc20s to loop through
   * @return _xerc20s The array of xerc20s from the start to start + amount
   */

  function getRegisteredXERC20(uint256 _start, uint256 _amount) external view returns (address[] memory _xerc20s);

  /**
   * @notice Returns if an XERC20 is registered
   *
   * @param _xerc20 The address of the XERC20
   * @return _result If the XERC20 is registered
   */

  function isRegisteredXERC20(address _xerc20) external view returns (bool _result);

  /**
   * @notice Returns the address of the lockbox for a given XERC20
   *
   * @param _xerc20 The address of the XERC20
   * @return _lockbox The address of the lockbox
   */

  function lockboxRegistry(address _xerc20) external view returns (address _lockbox);
}
