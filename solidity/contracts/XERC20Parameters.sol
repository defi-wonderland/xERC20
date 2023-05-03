// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {IXERC20} from 'interfaces/IXERC20.sol';
import {IXERC20Parameters} from 'interfaces/IXERC20Parameters.sol';
import {IXERC20Factory} from 'interfaces/IXERC20Factory.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract XERC20Parameters is ERC721, IXERC20Parameters {
  uint256 private constant _DURATION = 1 days;

  uint256 private _nextId;
  mapping(uint256 => Parameters) public params;
  IXERC20Factory public xerc20Factory;

  constructor(address _xerc20Factory) ERC721('XERC20Parameters', 'XPARAMS') {
    xerc20Factory = IXERC20Factory(_xerc20Factory);
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
  ) external {
    uint256 _mintersLength = _minters.length;
    if (_limits.length != _mintersLength) revert IXERC20Parameters_IncompatibleLengths();
    ++_nextId;

    address _token = xerc20Factory.deploy(_tokenName, _tokenSymbol, _nextId);

    params[_nextId].id = _nextId;
    params[_nextId].token = _token;

    uint256 _chainIdLength = _chainId.length;

    for (uint256 _i; _i < _chainIdLength;) {
      params[_nextId].chainId[_chainId[_i]] = true;

      unchecked {
        ++_i;
      }
    }

    for (uint256 _i; _i < _mintersLength;) {
      params[_nextId].maxLimit[_minters[_i]] = _limits[_i];
      params[_nextId].currentLimit[_minters[_i]] = _limits[_i];
      params[_nextId].ratePerSecond = params[_nextId].maxLimit[_minters[_i]] / _DURATION;
      params[_nextId].isMinter[_minters[_i]] = true;

      unchecked {
        ++_i;
      }
    }

    _mint(msg.sender, _nextId);

    emit ParamsCreated(_chainId, _limits, _minters);
  }

  /**
   * @notice Updates the limit of any minter
   * @dev Can only be called by the governance or owner of the NFT
   * @param _id Parameter NFT id
   * @param _limit The updated limit we are setting to the minter
   * @param _minter The address of the minter we are setting the limit too
   */

  function changeLimit(uint256 _id, uint256 _limit, address _minter) external {
    if (msg.sender != ownerOf(_id)) revert IXERC20Parameters_NotOwner();

    if (!params[_id].isMinter[_minter]) {
      params[_id].isMinter[_minter] = true;
    }

    uint256 _oldLimit = params[_id].maxLimit[_minter];
    params[_id].maxLimit[_minter] = _limit;
    params[_id].ratePerSecond = _limit / _DURATION;

    emit LimitsChanged(_id, _oldLimit, _limit, _minter);
  }

  /**
   * @notice Uses the limit of any minter
   * @dev Can only be called by the XERC20 token for the underlying parameters
   * @param _id Parameter NFT id
   * @param _change The change in the limit
   * @param _minter The address of the minter who is being changed
   */

  function useLimits(uint256 _id, uint256 _change, address _minter) external {
    if (msg.sender != params[_id].token) revert IXERC20Parameters_NotXERC20();

    uint256 _currentLimit = getCurrentLimit(_id, _minter);
    params[_id].timestamp = block.timestamp;
    params[_id].currentLimit[_minter] = _currentLimit - _change;
  }

  /**
   * @notice Updates the limit of any minter
   * @dev Can only be called by the governance or owner of the NFT
   * @param _id Parameter NFT id
   * @param _newChainId The new chainId we are whitelisting
   */

  function addChainId(uint256 _id, uint256 _newChainId) external {
    if (msg.sender != ownerOf(_id)) revert IXERC20Parameters_NotOwner();

    params[_id].chainId[_newChainId] = true;

    emit ChainIdAdded(_id, _newChainId);
  }

  /**
   * @notice Returns the max limit of a minter
   *
   * @param _id Parameter NFT id
   * @param _minter The minter we are viewing the limits of
   * @return _limit The limit the minter has
   */

  function getMaxLimit(uint256 _id, address _minter) public view returns (uint256 _limit) {
    _limit = params[_id].maxLimit[_minter];
  }

  /**
   * @notice Returns the current limit of a minter
   *
   * @param _id Parameter NFT id
   * @param _minter The minter we are viewing the limits of
   * @return _limit The limit the minter has
   */

  function getCurrentLimit(uint256 _id, address _minter) public view returns (uint256 _limit) {
    _limit = params[_id].currentLimit[_minter];
    uint256 _maxLimit = params[_id].maxLimit[_minter];

    if (params[_id].timestamp + _DURATION <= block.timestamp) {
      _limit = params[_id].maxLimit[_minter];
    } else if (params[_id].timestamp + _DURATION > block.timestamp) {
      uint256 _timePassed = block.timestamp - params[_id].timestamp;
      uint256 _calculatedLimit = _limit + (_timePassed * params[_id].ratePerSecond);
      _limit = _calculatedLimit > _maxLimit ? _maxLimit : _calculatedLimit;
    }
  }

  /**
   * @notice Returns the status of a chainId
   *
   * @param _id Parameter NFT id
   * @param _chainId The chainId we are checking the status of
   * @return _result The result of if a chainId is supported
   */

  function getChainIdStatus(uint256 _id, uint256 _chainId) public view returns (bool _result) {
    _result = params[_id].chainId[_chainId];
  }

  /**
   * @notice Returns the status of if a minter is approved to mint
   *
   * @param _id Parameter NFT id
   * @param _minter The minter we are checking the status of
   * @return _result The result of the check
   */

  function isMinterApproved(uint256 _id, address _minter) public view returns (bool _result) {
    _result = params[_id].isMinter[_minter];
  }
}
