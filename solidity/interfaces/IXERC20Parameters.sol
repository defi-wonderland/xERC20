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

  struct Parameters {
    uint256 id;
    address token;
    mapping(address => uint256) limits;
    mapping(uint256 => bool) chainId;
  }

  /**
   * @notice Creates a parameter config and deploys the XERC20
   *
   * @param _chainId array of starting chainIds the token should support
   */

  function createParams(uint256[] memory _chainId, uint256[] memory _limits, address[] memory _minters) external;

  /**
   * @notice Updates the limit of any minter
   * @dev Can only be called by the governance or owner of the NFT
   * @param _id Parameter NFT id
   * @param _limit The updated limit we are setting to the minter
   * @param _minter The address of the minter we are setting the limit too
   */

  function changeLimit(uint256 _id, uint256 _limit, address _minter) external;

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
   * @notice Returns the limit of a minter
   *
   * @param _id Parameter NFT id
   * @param _minter The minter we are viewing the limits of
   *  @return _limit The limit the minter has
   */
  function getLimits(uint256 _id, address _minter) external view returns (uint256 _limit);
}
