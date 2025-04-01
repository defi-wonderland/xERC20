// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IXERC20Factory {
  /**
   * @notice Emitted when a new XERC20 is deployed
   *
   * @param _xerc20 The address of the xerc20
   */
  event XERC20Deployed(address _xerc20);

  /**
   * @notice Emitted when a new XERC20Lockbox is deployed
   *
   * @param _lockbox The address of the lockbox
   */
  event LockboxDeployed(address _lockbox);

  /**
   * @notice Reverts when a non-owner attempts to call
   */
  error IXERC20Factory_NotOwner();

  /**
   * @notice Reverts when a the length of arrays sent is incorrect
   */
  error IXERC20Factory_InvalidLength();

  /**
   * @notice Deploys an XERC20 contract using CREATE3
   * @dev _limits and _minters must be the same length
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   * @param _decimals The number of decimals of the token
   * @param _owner The owner of the xerc20
   * @param _minterLimits The array of limits that you are adding (optional, can be an empty array)
   * @param _burnerLimits The array of limits that you are adding (optional, can be an empty array)
   * @param _bridges The array of bridges that you are adding (optional, can be an empty array)
   * @return _xerc20 The address of the xerc20
   */
  function deployXERC20(
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    address _owner,
    uint256[] memory _minterLimits,
    uint256[] memory _burnerLimits,
    address[] memory _bridges
  ) external returns (address _xerc20);

  /**
   * @notice Deploys an XERC20 and an XERC20Lockbox contract using CREATE3
   *
   * @dev When deploying a lockbox for the gas token of the chain, then, the base token needs to be address(0)
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   * @param _owner The owner of the xerc20
   * @param _minterLimits The array of limits that you are adding (optional, can be an empty array)
   * @param _burnerLimits The array of limits that you are adding (optional, can be an empty array)
   * @param _bridges The array of bridges that you are adding (optional, can be an empty array)
   * @param _baseToken The address of the base token that you want to lock
   * @param _isNative Whether or not the base token is the native (gas) token of the chain. Eg: MATIC for polygon chain
   * @return _xerc20 The address of the xerc20
   * @return _lockbox The address of the lockbox
   */
  function deployXERC20WithLockbox(
    string memory _name,
    string memory _symbol,
    address _owner,
    uint256[] memory _minterLimits,
    uint256[] memory _burnerLimits,
    address[] memory _bridges,
    address _baseToken,
    bool _isNative
  ) external returns (address _xerc20, address payable _lockbox);
}
