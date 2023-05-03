// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

interface IXERC20Parameters {
  /**
   * @notice Emits when a new parameter is created
   *
   * @param _chainId The array of chainIds to be added to the parameter
   * @param _limits The limits to be added to the minters
   * @param _minters The minters who will recieve the limits
   */

  event ParamsCreated(uint256[] _chainId, uint256[] _limits, address[] _minters);

  /**
   * @notice Emits when a new limit is added
   *
   * @param _id Parameter NFT id
   * @param _oldLimit The old limit of the minter
   * @param _newLimit The updated limit we are setting to the minter
   * @param _minter The address of the minter we are setting the limit too
   */

  event LimitsChanged(uint256 _id, uint256 _oldLimit, uint256 _newLimit, address _minter);

  /**
   * @notice Emits when a new chainId is added
   *
   * @param _id Parameter NFT id
   * @param _newChainId The new chainId we are whitelisting
   */

  event ChainIdAdded(uint256 _id, uint256 _newChainId);

  /**
   * @notice Reverts when the length of parallel arrays are not equal
   */

  error IXERC20Parameters_IncompatibleLengths();

  /**
   * @notice Reverts when a caller is not the owner of an NFT
   */

  error IXERC20Parameters_NotOwner();

  /**
   * @notice Reverts when a caller is not the token address of the XERC20
   */

  error IXERC20Parameters_NotXERC20();

  struct Parameters {
    uint256 id;
    address token;
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
   * @param _chainId The array of chainIds to be added to the parameter
   * @param _limits The limits to be added to the minters
   * @param _minters The minters who will recieve the limits
   * @param _tokenName The name of the token you are deploying
   * @param _tokenSymbol The symbol of the token you are deploying
   */

  function createParams(
    uint256[] memory _chainId,
    uint256[] memory _limits,
    address[] memory _minters,
    string memory _tokenName,
    string memory _tokenSymbol
  ) external;

  /**
   * @notice Updates the limit of any minter
   * @dev Can only be called by the governance or owner of the NFT
   * @param _id Parameter NFT id
   * @param _limit The updated limit we are setting to the minter
   * @param _minter The address of the minter we are setting the limit too
   */

  function changeLimit(uint256 _id, uint256 _limit, address _minter) external;

  /**
   * @notice Uses the limit of any minter
   * @dev Can only be called by the XERC20 token for the underlying parameters
   * @param _id Parameter NFT id
   * @param _change The change in the limit
   * @param _minter The address of the minter who is being changed
   */

  function useLimits(uint256 _id, uint256 _change, address _minter) external;

  /**
   * @notice Updates the limit of any minter
   * @dev Can only be called by the governance or owner of the NFT
   * @param _id Parameter NFT id
   * @param _newChainId The new chainId we are whitelisting
   */

  function addChainId(uint256 _id, uint256 _newChainId) external;

  /**
   * @notice Returns the status of a chainId
   *
   * @param _id Parameter NFT id
   * @param _chainId The chainId we are checking the status of
   * @return _result The result of if a chainId is supported
   */

  function getChainIdStatus(uint256 _id, uint256 _chainId) external view returns (bool _result);

  /**
   * @notice Returns the max limit of a minter
   *
   * @param _id Parameter NFT id
   * @param _minter The minter we are viewing the limits of
   *  @return _limit The limit the minter has
   */
  function getMaxLimit(uint256 _id, address _minter) external view returns (uint256 _limit);

  /**
   * @notice Returns the current limit of a minter
   *
   * @param _id Parameter NFT id
   * @param _minter The minter we are viewing the limits of
   * @return _limit The limit the minter has
   */

  function getCurrentLimit(uint256 _id, address _minter) external view returns (uint256 _limit);

  /**
   * @notice Returns the status of if a minter is approved to mint
   *
   * @param _id Parameter NFT id
   * @param _minter The minter we are checking the status of
   * @return _result The result of the check
   */

  function isMinterApproved(uint256 _id, address _minter) external view returns (bool _result);
}
