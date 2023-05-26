// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {IXERC20} from 'interfaces/IXERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {ERC20Permit} from '@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

contract XERC20 is ERC20, Ownable, IXERC20, ERC20Permit {
  using EnumerableSet for EnumerableSet.AddressSet;

  /**
   * @notice The duration it takes for the limits to fully replenish
   */
  uint256 private constant _DURATION = 1 days;

  /**
   * @notice The address of the factory which deployed this contract
   */
  address public immutable FACTORY;

  /**
   * @notice The address of the lockbox contract
   */
  address public lockbox;

  /**
   * @notice The set of whitelisted bridges
   */
  EnumerableSet.AddressSet internal _bridgesSet;

  /**
   * @notice Maps bridge address to bridge configurations
   */
  mapping(address => Bridge) public bridges;

  /**
   * @notice Constructs the initial config of the XERC20
   *
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   * @param _factory The factory which deployed this contract
   */

  constructor(
    string memory _name,
    string memory _symbol,
    address _factory
  ) ERC20(string.concat('x', _name), string.concat('x', _symbol)) ERC20Permit(string.concat('x', _name)) {
    _transferOwnership(_factory);
    FACTORY = _factory;
  }

  /**
   * @notice Mints tokens for a user
   * @dev Can only be called by a bridge
   * @param _user The address of the user who needs tokens minted
   * @param _amount The amount of tokens being minted
   */

  function mint(address _user, uint256 _amount) public {
    _mintWithCaller(msg.sender, _user, _amount);
  }

  /**
   * @notice Burns tokens for a user
   * @dev Can only be called by a bridge
   * @param _user The address of the user who needs tokens burned
   * @param _amount The amount of tokens being burned
   */

  function burn(address _user, uint256 _amount) public {
    _burnWithCaller(msg.sender, _user, _amount);
  }
  /**
   * @notice Overrides transfer to call burn/mint based on the recipient
   * @dev Some bridges transfer instead of minting/burning. In that case, if you transfer tokens to a bridges we burn them and if the bridges transfers tokens we mint for the recipient, if neither apply we will just call the ERC20 transfer
   * @param _to The address of the recipient
   * @param _amount The amount of tokens to transfer
   */

  function transfer(address _to, uint256 _amount) public override returns (bool _result) {
    bool _senderIsBridge = bridges[msg.sender].isBridge;
    bool _receiverIsBridge = bridges[_to].isBridge;

    if (_senderIsBridge && _receiverIsBridge) {
      _mintWithCaller(msg.sender, msg.sender, _amount);
      _burnWithCaller(_to, msg.sender, _amount);
      _result = true;
    } else {
      if (_senderIsBridge) {
        _mintWithCaller(msg.sender, _to, _amount);
        _result = true;
      }

      if (_receiverIsBridge) {
        _burnWithCaller(_to, msg.sender, _amount);
        _result = true;
      }
    }

    if (!_result) _result = super.transfer(_to, _amount);
  }

  /**
   * _
   * @notice Overrides transfer to call burn/mint based on the recipient
   * @dev Some bridges transfer instead of minting/burning. In that case, if you transfer tokens to a bridges we burn them and if the bridges transfers tokens we mint for the recipient, if neither apply we will just call the ERC20 transferFrom
   * @param _from The address of the sender
   * @param _to The address of the recipient
   * @param _amount The amount of tokens to transfer
   */

  function transferFrom(address _from, address _to, uint256 _amount) public override returns (bool _result) {
    bool _senderIsBridge = bridges[_from].isBridge;
    bool _receiverIsBridge = bridges[_to].isBridge;

    if (_senderIsBridge && _receiverIsBridge) {
      _spendAllowance(_from, msg.sender, _amount);
      _mintWithCaller(msg.sender, msg.sender, _amount);
      _burnWithCaller(_to, msg.sender, _amount);

      _result = true;
    } else {
      if (_senderIsBridge) {
        _spendAllowance(_from, msg.sender, _amount);

        _mintWithCaller(_from, _to, _amount);
        _result = true;
      }

      if (_receiverIsBridge) {
        _spendAllowance(_from, msg.sender, _amount);

        _burnWithCaller(_to, _from, _amount);
        _result = true;
      }
    }

    if (!_result) _result = super.transferFrom(_from, _to, _amount);
  }

  /**
   * @notice Sets the lockbox address
   *
   * @param _lockbox The address of the lockbox
   */

  function setLockbox(address _lockbox) public {
    if (msg.sender != FACTORY) revert IXERC20_NotFactory();
    lockbox = _lockbox;

    emit LockboxSet(_lockbox);
  }

  /**
   * @notice Creates limits for bridges
   * @dev _limits and _bridges are parallel arrays and should be the same length
   * @param _limits The limits to be added to the bridges
   * @param _bridges the bridges who will recieve the limits
   */

  function createBridgeMintingLimits(uint256[] memory _limits, address[] memory _bridges) external onlyOwner {
    uint256 _bridgesLength = _bridges.length;
    if (_limits.length != _bridgesLength) revert IXERC20_IncompatibleLengths();

    for (uint256 _i; _i < _bridgesLength;) {
      _changeLimit(_limits[_i], _bridges[_i], true);
      unchecked {
        ++_i;
      }
    }
  }

  /**
   * @notice Creates limits for bridges
   * @dev _limits and _bridges are parallel arrays and should be the same length
   * @param _limits The limits to be added to the bridges
   * @param _bridges the bridges who will recieve the limits
   */

  function createBridgeBurningLimits(uint256[] memory _limits, address[] memory _bridges) external onlyOwner {
    uint256 _bridgesLength = _bridges.length;
    if (_limits.length != _bridgesLength) revert IXERC20_IncompatibleLengths();

    for (uint256 _i; _i < _bridgesLength;) {
      _changeLimit(_limits[_i], _bridges[_i], false);

      unchecked {
        ++_i;
      }
    }
  }

  /**
   * @notice Updates the limit of any bridge
   * @dev Can only be called by the owner
   * @param _limit The updated limit we are setting to the bridge
   * @param _bridge The address of the bridge we are setting the limit too
   */

  function changeBridgeMintingLimit(uint256 _limit, address _bridge) external onlyOwner {
    _changeLimit(_limit, _bridge, true);
  }

  /**
   * @notice Updates the limit of any bridge
   * @dev Can only be called by the owner
   * @param _limit The updated limit we are setting to the bridge
   * @param _bridge The address of the bridge we are setting the limit too
   */

  function changeBridgeBurningLimit(uint256 _limit, address _bridge) external onlyOwner {
    _changeLimit(_limit, _bridge, false);
  }

  /**
   * @notice Removes a bridge
   * @dev Can only be called by the owner
   * @dev @dev Calling removeBridge transforms a bridge into a normal user. Meaning that they will be able to receive/send tokens as a normal user. If you want to pause operations for a bridge minting/burning limits should be set to 0.
   * @param _bridge The bridge we are removing
   */

  function removeBridge(address _bridge) external onlyOwner {
    delete bridges[_bridge];
  }

  /**
   * @notice Returns the max limit of a bridge
   *
   * @param _bridge the bridge we are viewing the limits of
   * @return _limit The limit the bridge has
   */

  function mintingMaxLimitOf(address _bridge) public view returns (uint256 _limit) {
    _limit = bridges[_bridge].minterParams.maxLimit;
  }

  /**
   * @notice Returns the max limit of a bridge
   *
   * @param _bridge the bridge we are viewing the limits of
   * @return _limit The limit the bridge has
   */

  function burningMaxLimitOf(address _bridge) public view returns (uint256 _limit) {
    _limit = bridges[_bridge].burnerParams.maxLimit;
  }

  /**
   * @notice Returns the current limit of a bridge
   *
   * @param _bridge the bridge we are viewing the limits of
   * @return _limit The limit the bridge has
   */

  function mintingCurrentLimitOf(address _bridge) public view returns (uint256 _limit) {
    _limit = _getCurrentLimit(
      bridges[_bridge].minterParams.currentLimit,
      bridges[_bridge].minterParams.maxLimit,
      bridges[_bridge].minterParams.timestamp,
      bridges[_bridge].minterParams.ratePerSecond
    );
  }

  /**
   * @notice Returns the current limit of a bridge
   *
   * @param _bridge the bridge we are viewing the limits of
   * @return _limit The limit the bridge has
   */

  function burningCurrentLimitOf(address _bridge) public view returns (uint256 _limit) {
    _limit = _getCurrentLimit(
      bridges[_bridge].burnerParams.currentLimit,
      bridges[_bridge].burnerParams.maxLimit,
      bridges[_bridge].burnerParams.timestamp,
      bridges[_bridge].burnerParams.ratePerSecond
    );
  }

  /**
   * @notice Loops through the array of bridges
   *
   * @param _start The start of the loop
   * @param _amount The amount of bridges to loop through
   * @return _bridges The array of bridges from the start to start + amount
   */

  function getBridges(uint256 _start, uint256 _amount) external view returns (address[] memory _bridges) {
    uint256 _bridgesLength = EnumerableSet.length(_bridgesSet);
    if (_amount > _bridgesLength - _start) {
      _amount = _bridgesLength - _start;
    }

    _bridges = new address[](_amount);
    uint256 _index;
    while (_index < _amount) {
      _bridges[_index] = EnumerableSet.at(_bridgesSet, _start + _index);

      unchecked {
        ++_index;
      }
    }
  }

  /**
   * @notice Uses the limit of any bridge
   * @param _change The change in the limit
   * @param _bridge The address of the bridge who is being changed
   */

  function _useMinterLimits(uint256 _change, address _bridge) internal {
    uint256 _currentLimit = mintingCurrentLimitOf(_bridge);
    bridges[_bridge].minterParams.timestamp = block.timestamp;
    bridges[_bridge].minterParams.currentLimit = _currentLimit - _change;
  }

  /**
   * @notice Uses the limit of any bridge
   * @param _change The change in the limit
   * @param _bridge The address of the bridge who is being changed
   */

  function _useBurnerLimits(uint256 _change, address _bridge) internal {
    uint256 _currentLimit = burningCurrentLimitOf(_bridge);
    bridges[_bridge].burnerParams.timestamp = block.timestamp;
    bridges[_bridge].burnerParams.currentLimit = _currentLimit - _change;
  }

  /**
   * @notice Updates the limit of any bridge
   * @dev Can only be called by the owner
   * @param _limit The updated limit we are setting to the bridge
   * @param _bridge The address of the bridge we are setting the limit too
   */

  function _changeMinterLimit(uint256 _limit, address _bridge) internal {
    uint256 _oldLimit = bridges[_bridge].minterParams.maxLimit;
    uint256 _currentLimit = mintingCurrentLimitOf(_bridge);
    bridges[_bridge].minterParams.maxLimit = _limit;

    bridges[_bridge].minterParams.currentLimit = _calculateNewCurrentLimit(_limit, _oldLimit, _currentLimit);

    bridges[_bridge].minterParams.ratePerSecond = _limit / _DURATION;
    bridges[_bridge].minterParams.timestamp = block.timestamp;
    emit MinterLimitsSet(_limit, _bridge);
  }

  /**
   * @notice Updates the limit of any bridge
   * @dev Can only be called by the owner
   * @param _limit The updated limit we are setting to the bridge
   * @param _bridge The address of the bridge we are setting the limit too
   */

  function _changeBurnerLimit(uint256 _limit, address _bridge) internal {
    uint256 _oldLimit = bridges[_bridge].burnerParams.maxLimit;
    uint256 _currentLimit = burningCurrentLimitOf(_bridge);
    bridges[_bridge].burnerParams.maxLimit = _limit;

    bridges[_bridge].burnerParams.currentLimit = _calculateNewCurrentLimit(_limit, _oldLimit, _currentLimit);

    bridges[_bridge].burnerParams.ratePerSecond = _limit / _DURATION;
    bridges[_bridge].burnerParams.timestamp = block.timestamp;
    emit BurnerLimitsSet(_limit, _bridge);
  }

  /**
   * @notice Updates the limit of any bridge
   *
   * @param _newLimit The updated limit we are setting to the bridge
   * @param _bridge The address of the bridge we are setting the limit too
   * @param _mintingLimit Whether or not we are updating the minting limit
   */

  function _changeLimit(uint256 _newLimit, address _bridge, bool _mintingLimit) internal {
    if (_newLimit != 0 && !bridges[_bridge].isBridge) {
      bridges[_bridge].isBridge = true;
      EnumerableSet.add(_bridgesSet, _bridge);
    }

    if (_mintingLimit) {
      _changeMinterLimit(_newLimit, _bridge);
    } else {
      _changeBurnerLimit(_newLimit, _bridge);
    }
  }

  /**
   * @notice Updates the current limit
   *
   * @param _limit The new limit
   * @param _oldLimit The old limit
   * @param _currentLimit The current limit
   */

  function _calculateNewCurrentLimit(
    uint256 _limit,
    uint256 _oldLimit,
    uint256 _currentLimit
  ) internal pure returns (uint256 _newCurrentLimit) {
    uint256 _difference;

    if (_oldLimit > _limit) {
      _difference = _oldLimit - _limit;
      _newCurrentLimit = _currentLimit > _difference ? _currentLimit - _difference : 0;
    } else {
      _difference = _limit - _oldLimit;
      _newCurrentLimit = _currentLimit + _difference;
    }
  }

  /**
   * @notice Gets the current limit
   *
   * @param _currentLimit The current limit
   * @param _maxLimit The max limit
   * @param _timestamp The timestamp of the last update
   * @param _ratePerSecond The rate per second
   */

  function _getCurrentLimit(
    uint256 _currentLimit,
    uint256 _maxLimit,
    uint256 _timestamp,
    uint256 _ratePerSecond
  ) internal view returns (uint256 _limit) {
    _limit = _currentLimit;
    if (_limit == _maxLimit) {
      return _limit;
    } else if (_timestamp + _DURATION <= block.timestamp) {
      _limit = _maxLimit;
    } else if (_timestamp + _DURATION > block.timestamp) {
      uint256 _timePassed = block.timestamp - _timestamp;
      uint256 _calculatedLimit = _limit + (_timePassed * _ratePerSecond);
      _limit = _calculatedLimit > _maxLimit ? _maxLimit : _calculatedLimit;
    }
  }

  /**
   * @notice Internal function for burning tokens
   *
   * @param _caller The caller address
   * @param _user The user address
   * @param _amount The amount to burn
   */

  function _burnWithCaller(address _caller, address _user, uint256 _amount) internal {
    if (_caller != lockbox) {
      uint256 _currentLimit = burningCurrentLimitOf(_caller);
      if (_currentLimit < _amount) revert IXERC20_NotHighEnoughLimits();
      _useBurnerLimits(_amount, _caller);
    }
    _burn(_user, _amount);
  }

  /**
   * @notice Internal function for minting tokens
   *
   * @param _caller The caller address
   * @param _user The user address
   * @param _amount The amount to mint
   */

  function _mintWithCaller(address _caller, address _user, uint256 _amount) internal {
    if (_caller != lockbox) {
      uint256 _currentLimit = mintingCurrentLimitOf(_caller);
      if (_currentLimit < _amount) revert IXERC20_NotHighEnoughLimits();
      _useMinterLimits(_amount, _caller);
    }
    _mint(_user, _amount);
  }
}
