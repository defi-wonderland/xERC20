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

  struct Parameters {
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
   * @notice Creates a parameter config and deploys the XERC20
   * @dev _limits and _minters are parallel arrays and should be the same length
   * @param _limits The limits to be added to the minters
   * @param _minters The minters who will recieve the limits
   */

  function createMinterLimits(uint256[] memory _limits, address[] memory _minters) external;

  /**
   * @notice Updates the limit of any minter
   * @dev Can only be called by the governance or owner of the NFT
   * @param _limit The updated limit we are setting to the minter
   * @param _minter The address of the minter we are setting the limit too
   */

  function changeMinterLimit(uint256 _limit, address _minter) external;

  /**
   * @notice Removes a burner
   * @dev Can only be called by the owner
   * @param _burner The burner we are removing
   */

  function removeBurner(address _burner) external;

  /**
   * @notice Removes a minter
   * @dev Can only be called by the owner
   * @param _minter The minter we are removing
   */

  function removeMinter(address _minter) external;

  /**
   * @notice Returns the max limit of a minter
   *
   * @param _minter The minter we are viewing the limits of
   *  @return _limit The limit the minter has
   */
  function getMinterMaxLimit(address _minter) external view returns (uint256 _limit);

  /**
   * @notice Returns the current limit of a minter
   *
   * @param _minter The minter we are viewing the limits of
   * @return _limit The limit the minter has
   */

  function getMinterCurrentLimit(address _minter) external view returns (uint256 _limit);

  /**
   * @notice Loops through the array of burners
   *
   * @param _start The start of the loop
   * @param _amount The amount of burners to loop through
   * @return _burners The array of burners from the start to the end of the loop
   */

  function getBurners(uint256 _start, uint256 _amount) external view returns (address[] memory _burners);

  /**
   * @notice Loops through the array of minters
   *
   * @param _start The start of the loop
   * @param _amount The amount of minters to loop through
   * @return _minters The array of minters from the start to the end of the loop
   */

  function getMinters(uint256 _start, uint256 _amount) external view returns (address[] memory _minters);

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
