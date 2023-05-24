// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

interface IXERC20 {
  /**
   * @notice Emits when a lockbox is set
   *
   * @param _lockbox The address of the lockbox
   */

  event LockboxSet(address _lockbox);

  /**
   * @notice Emits when a limit is set
   *
   * @param _newLimit The updated limit we are setting to the minter
   * @param _minter The address of the minter we are setting the limit too
   */

  event MinterLimitsSet(uint256 _newLimit, address indexed _minter);

  /**
   * @notice Emits when a limit is set
   *
   * @param _newLimit The updated limit we are setting to the minter
   * @param _burner The address of the minter we are setting the limit too
   */

  event BurnerLimitsSet(uint256 _newLimit, address indexed _burner);

  /**
   * @notice Reverts when a user with too low of a limit tries to call mint/burn
   */

  error IXERC20_NotHighEnoughLimits();

  /**
   * @notice Reverts when caller is not the factory
   */

  error IXERC20_NotFactory();

  /**
   * @notice Reverts when the length of parallel arrays are not equal
   */

  error IXERC20_IncompatibleLengths();

  struct Bridge {
    bool isBridge;
    BridgeParameters minterParams;
    BridgeParameters burnerParams;
  }

  struct BridgeParameters {
    uint256 timestamp;
    uint256 ratePerSecond;
    uint256 maxLimit;
    uint256 currentLimit;
    bool isBridge;
  }

  /**
   * @notice Sets the lockbox address
   *
   * @param _lockbox The address of the lockbox
   */

  function setLockbox(address _lockbox) external;

  /**
   * @notice Creates limits for bridges
   * @dev _limits and _bridges are parallel arrays and should be the same length
   * @param _limits The limits to be added to the bridges
   * @param _bridges the bridges who will recieve the limits
   */

  function createBridgeMintingLimits(uint256[] memory _limits, address[] memory _bridges) external;

  /**
   * @notice Creates limits for bridges
   * @dev _limits and _bridges are parallel arrays and should be the same length
   * @param _limits The limits to be added to the bridges
   * @param _bridges the bridges who will recieve the limits
   */

  function createBridgeBurningLimits(uint256[] memory _limits, address[] memory _bridges) external;

  /**
   * @notice Updates the limit of any bridge
   * @dev Can only be called by the owner
   * @param _limit The updated limit we are setting to the bridge
   * @param _bridge The address of the bridge we are setting the limit too
   */

  function changeBridgeMintingLimit(uint256 _limit, address _bridge) external;

  /**
   * @notice Updates the limit of any bridge
   * @dev Can only be called by the owner
   * @param _limit The updated limit we are setting to the bridge
   * @param _bridge The address of the bridge we are setting the limit too
   */

  function changeBridgeBurningLimit(uint256 _limit, address _bridge) external;

  /**
   * @notice Removes a bridge
   * @dev Can only be called by the owner
   * @param _bridge The bridge we are removing
   */

  function removeBridge(address _bridge) external;

  /**
   * @notice Returns the max limit of a minter
   *
   * @param _minter The minter we are viewing the limits of
   *  @return _limit The limit the minter has
   */
  function getMintingMaxLimit(address _minter) external view returns (uint256 _limit);

  /**
   * @notice Returns the max limit of a bridge
   *
   * @param _bridge the bridge we are viewing the limits of
   * @return _limit The limit the bridge has
   */

  function getBurningMaxLimit(address _bridge) external view returns (uint256 _limit);

  /**
   * @notice Returns the current limit of a minter
   *
   * @param _minter The minter we are viewing the limits of
   * @return _limit The limit the minter has
   */

  function getMintingCurrentLimit(address _minter) external view returns (uint256 _limit);

  /**
   * @notice Returns the current limit of a bridge
   *
   * @param _bridge the bridge we are viewing the limits of
   * @return _limit The limit the bridge has
   */

  function getBurningCurrentLimit(address _bridge) external view returns (uint256 _limit);

  /**
   * @notice Loops through the array of bridges
   *
   * @param _start The start of the loop
   * @param _amount The amount of bridges to loop through
   * @return _bridges The array of bridges from the start to the end of the loop
   */

  function getBridges(uint256 _start, uint256 _amount) external view returns (address[] memory _bridges);

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
