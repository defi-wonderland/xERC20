// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {IXERC20} from 'interfaces/IXERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {ERC20Permit} from '@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract XERC20 is ERC20, Ownable, IXERC20, ERC20Permit {
  uint256 private constant _DURATION = 1 days;

  Parameters public params;

  /**
   * @notice Constructs the initial config of the XERC20
   *
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   */

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC20(string.concat('x', _name), string.concat('x', _symbol)) ERC20Permit(string.concat('x', _name)) {}

  /**
   * @notice Mints tokens for a user
   * @dev Can only be called by a minter
   * @param _user The address of the user who needs tokens minted
   * @param _amount The amount of tokens being minted
   */

  function mint(address _user, uint256 _amount) external {
    if (!params.isMinter[msg.sender]) revert IXERC20_NotApprovedMinter();
    _mint(_user, _amount);
  }

  /**
   * @notice Burns tokens for a user
   * @dev Can only be called by a minter
   * @param _user The address of the user who needs tokens burned
   * @param _amount The amount of tokens being burned
   */

  function burn(address _user, uint256 _amount) external {
    uint256 _currentLimit = getCurrentLimit(msg.sender);
    if (_currentLimit < _amount) revert IXERC20_NotHighEnoughLimits();
    _useLimits(_amount, msg.sender);
    _burn(_user, _amount);
  }

  /**
   * @notice Creates a parameter config and deploys the XERC20
   * @dev _limits and _minters are parallel arrays and should be the same length
   * @param _limits The limits to be added to the minters
   * @param _minters The minters who will recieve the limits
   */

  function createLimits(uint256[] memory _limits, address[] memory _minters) external onlyOwner {
    uint256 _mintersLength = _minters.length;
    if (_limits.length != _mintersLength) revert IXERC20_IncompatibleLengths();

    for (uint256 _i; _i < _mintersLength;) {
      if (params.maxLimit[_minters[_i]] != 0 || _limits[_i] == 0) {
        changeLimit(_limits[_i], _minters[_i]);
      } else {
        params.maxLimit[_minters[_i]] = _limits[_i];
        params.currentLimit[_minters[_i]] = _limits[_i];
        params.ratePerSecond = params.maxLimit[_minters[_i]] / _DURATION;
        params.isMinter[_minters[_i]] = true;
      }

      unchecked {
        ++_i;
      }
    }

    emit LimitsCreated(_limits, _minters);
  }

  /**
   * @notice Creates a parameter config and deploys the XERC20
   * @dev Can only be called by owner
   * @param _chainId An array of chainIds you are whitelisting for this token
   */

  function createChainIds(uint256[] memory _chainId) external onlyOwner {
    uint256 _chainIdLength = _chainId.length;

    for (uint256 _i; _i < _chainIdLength;) {
      params.chainId[_chainId[_i]] = true;

      unchecked {
        ++_i;
      }
    }

    emit ChainIdsCreated(_chainId);
  }

  /**
   * @notice Updates the limit of any minter
   * @dev Can only be called by the governance or owner
   * @param _limit The updated limit we are setting to the minter
   * @param _minter The address of the minter we are setting the limit too
   */

  function changeLimit(uint256 _limit, address _minter) public onlyOwner {
    if (!params.isMinter[_minter]) {
      params.isMinter[_minter] = true;
    }

    // If limit is being moved to zero we should remove minter rights
    if (_limit == 0) params.isMinter[_minter] = false;

    uint256 _oldLimit = params.maxLimit[_minter];
    uint256 _currentLimit = getCurrentLimit(_minter);
    params.maxLimit[_minter] = _limit;
    uint256 _difference;

    if (_oldLimit > _limit) {
      _difference = _oldLimit - _limit;
      params.currentLimit[_minter] = _currentLimit > _difference ? _currentLimit - _difference : 0;
    } else {
      _difference = _limit - _oldLimit;
      params.currentLimit[_minter] = _currentLimit + _difference;
    }

    params.ratePerSecond = _limit / _DURATION;
    params.timestamp = block.timestamp;
    emit LimitsChanged(_oldLimit, _limit, _minter);
  }

  /**
   * @notice Updates the limit of any minter
   * @dev Can only be called by the governance or owner of the NFT
   *  Parameter NFT id
   * @param _newChainId The new chainId we are whitelisting
   */

  function addChainId(uint256 _newChainId) external onlyOwner {
    params.chainId[_newChainId] = true;

    emit ChainIdAdded(_newChainId);
  }

  /**
   * @notice Returns the max limit of a minter
   *
   * @param _minter The minter we are viewing the limits of
   * @return _limit The limit the minter has
   */

  function getMaxLimit(address _minter) public view returns (uint256 _limit) {
    _limit = params.maxLimit[_minter];
  }

  /**
   * @notice Returns the current limit of a minter
   *
   * @param _minter The minter we are viewing the limits of
   * @return _limit The limit the minter has
   */

  function getCurrentLimit(address _minter) public view returns (uint256 _limit) {
    _limit = params.currentLimit[_minter];
    uint256 _maxLimit = params.maxLimit[_minter];
    if (_limit == _maxLimit) {
      return _limit;
    } else if (params.timestamp + _DURATION <= block.timestamp) {
      _limit = params.maxLimit[_minter];
    } else if (params.timestamp + _DURATION > block.timestamp) {
      uint256 _timePassed = block.timestamp - params.timestamp;
      uint256 _calculatedLimit = _limit + (_timePassed * params.ratePerSecond);
      _limit = _calculatedLimit > _maxLimit ? _maxLimit : _calculatedLimit;
    }
  }

  /**
   * @notice Returns the status of a chainId
   *
   * @param _chainId The chainId we are checking the status of
   * @return _result The result of if a chainId is supported
   */

  function getChainIdStatus(uint256 _chainId) public view returns (bool _result) {
    _result = params.chainId[_chainId];
  }

  /**
   * @notice Returns the status of if a minter is approved to mint
   *
   * @param _minter The minter we are checking the status of
   * @return _result The result of the check
   */

  function isMinterApproved(address _minter) public view returns (bool _result) {
    _result = params.isMinter[_minter];
  }

  /**
   * @notice Uses the limit of any minter
   * @param _change The change in the limit
   * @param _minter The address of the minter who is being changed
   */

  function _useLimits(uint256 _change, address _minter) internal {
    uint256 _currentLimit = getCurrentLimit(_minter);
    params.timestamp = block.timestamp;
    params.currentLimit[_minter] = _currentLimit - _change;
  }
}
