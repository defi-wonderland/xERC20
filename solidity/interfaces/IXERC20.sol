// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

interface IXERC20 {
  /**
   * @notice Emits when multiple limits are added
   *
   * @param _limits The limits to be added to the minters
   * @param _minters The minters who will recieve the limits
   */

  event LimitsCreated(uint256[] _limits, address[] _minters);
  /**
   * @notice Emits when multiple chain id's are whitelisted
   *
   * @param _chainId The array of chainIds to be added to the parameter
   */

  event ChainIdsCreated(uint256[] _chainId);

  /**
   * @notice Emits when a new limit is added
   *
   * @param _oldLimit The old limit of the minter
   * @param _newLimit The updated limit we are setting to the minter
   * @param _minter The address of the minter we are setting the limit too
   */

  event LimitsChanged(uint256 _oldLimit, uint256 _newLimit, address _minter);

  /**
   * @notice Emits when a new chainId is added
   *
   * @param _newChainId The new chainId we are whitelisting
   */

  event ChainIdAdded(uint256 _newChainId);

  /**
   * @notice Reverts when a user with too low of a limit tries to call mint/burn
   */

  error IXERC20_NotHighEnoughLimits();

  /**
   * @notice Reverts when a user tries to mint who isn't approved
   */

  error IXERC20_NotApprovedMinter();

  /**
   * @notice Reverts when the length of parallel arrays are not equal
   */

  error IXERC20_IncompatibleLengths();

  /**
   * @notice Reverts when a caller is not the owner of an NFT
   */

  error IXERC20_NotOwner();

  /**
   * @notice Reverts when a caller is not the token address of the XERC20
   */

  error IXERC20_NotXERC20();

  struct Parameters {
    uint256 timestamp;
    uint256 ratePerSecond;
    mapping(address => uint256) maxLimit;
    mapping(address => uint256) currentLimit;
    mapping(uint256 => bool) chainId;
    mapping(address => bool) isMinter;
  }

  /**
   * @notice Creates a parameter config and deploys the XERC20
   * @dev _limits and _minters are parallel arrays and should be the same length
   * @param _limits The limits to be added to the minters
   * @param _minters The minters who will recieve the limits
   */

  function createLimits(uint256[] memory _limits, address[] memory _minters) external;

  /**
   * @notice Creates a parameter config and deploys the XERC20
   * @dev Can only be called by owner
   * @param _chainId An array of chainIds you are whitelisting for this token
   */

  function createChainIds(uint256[] memory _chainId) external;

  /**
   * @notice Updates the limit of any minter
   * @dev Can only be called by the governance or owner of the NFT
   * @param _limit The updated limit we are setting to the minter
   * @param _minter The address of the minter we are setting the limit too
   */

  function changeLimit(uint256 _limit, address _minter) external;

  /**
   * @notice Updates the limit of any minter
   * @dev Can only be called by the governance or owner of the NFT
   * @param _newChainId The new chainId we are whitelisting
   */

  function addChainId(uint256 _newChainId) external;

  /**
   * @notice Returns the status of a chainId
   *
   * @param _chainId The chainId we are checking the status of
   * @return _result The result of if a chainId is supported
   */

  function getChainIdStatus(uint256 _chainId) external view returns (bool _result);

  /**
   * @notice Returns the max limit of a minter
   *
   * @param _minter The minter we are viewing the limits of
   *  @return _limit The limit the minter has
   */
  function getMaxLimit(address _minter) external view returns (uint256 _limit);

  /**
   * @notice Returns the current limit of a minter
   *
   * @param _minter The minter we are viewing the limits of
   * @return _limit The limit the minter has
   */

  function getCurrentLimit(address _minter) external view returns (uint256 _limit);

  /**
   * @notice Returns the status of if a minter is approved to mint
   *
   * @param _minter The minter we are checking the status of
   * @return _result The result of the check
   */

  function isMinterApproved(address _minter) external view returns (bool _result);

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
