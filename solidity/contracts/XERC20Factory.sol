// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {XERC20} from '../contracts/XERC20.sol';
import {IXERC20Factory} from '../interfaces/IXERC20Factory.sol';
import {XERC20Lockbox} from '../contracts/XERC20Lockbox.sol';
import {CREATE3} from 'isolmate/utils/CREATE3.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

contract XERC20Factory is IXERC20Factory {
  using EnumerableSet for EnumerableSet.AddressSet;

  /**
  * @notice The address of the old factory
  */
  XERC20Factory public immutable OLD_FACTORY;

  /**
   * @notice Address of the xerc20 maps to the address of its lockbox if it has one
   */
  mapping(address => address) internal _lockboxRegistry;

  /**
   * @notice The set of registered lockboxes
   */
  EnumerableSet.AddressSet internal _lockboxRegistryArray;

  /**
   * @notice The set of registered XERC20 tokens
   */
  EnumerableSet.AddressSet internal _xerc20RegistryArray;

  constructor(address _oldFactory) {
    OLD_FACTORY = XERC20Factory(_oldFactory);
  }

  /**
   * @notice Deploys an XERC20 contract using CREATE3
   * @dev _limits and _minters must be the same length
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   * @param _minterLimits The array of limits that you are adding (optional, can be an empty array)
   * @param _burnerLimits The array of limits that you are adding (optional, can be an empty array)
   * @param _bridges The array of bridges that you are adding (optional, can be an empty array)
   */

  function deployXERC20(
    string memory _name,
    string memory _symbol,
    uint256[] memory _minterLimits,
    uint256[] memory _burnerLimits,
    address[] memory _bridges
  ) external returns (address _xerc20) {
    _xerc20 = _deployXERC20(_name, _symbol, _minterLimits, _burnerLimits, _bridges);

    emit XERC20Deployed(_xerc20);
  }

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
  ) external returns (address payable _lockbox) {
    if (_baseToken == address(0) && !_isNative) revert IXERC20Factory_BadTokenAddress();

    if (XERC20(_xerc20).owner() != msg.sender) revert IXERC20Factory_NotOwner();
    if (_getLockboxForXERC20(_xerc20) != address(0)) revert IXERC20Factory_LockboxAlreadyDeployed();

    _lockbox = _deployLockbox(_xerc20, _baseToken, _isNative);

    emit LockboxDeployed(_lockbox);
  }

  /**
   * @notice Loops through the xerc20RegistryArray
   *
   * @param _start The start of the loop
   * @param _amount The end of the loop
   * @return _lockboxes The array of xerc20s from the start to start + amount
   */

  function getRegisteredLockboxes(uint256 _start, uint256 _amount) public view returns (address[] memory _lockboxes) {
    _lockboxes = _getRegisteredSet(_start, _amount, _lockboxRegistryArray);
  }

  /**
   * @notice Loops through the xerc20RegistryArray
   *
   * @param _start The start of the loop
   * @param _amount The amount of xerc20s to loop through
   * @return _xerc20s The array of xerc20s from the start to start + amount
   */

  function getRegisteredXERC20(uint256 _start, uint256 _amount) public view returns (address[] memory _xerc20s) {
    _xerc20s = _getRegisteredSet(_start, _amount, _xerc20RegistryArray);
  }

  /**
   * @notice Returns if an XERC20 is registered
   *
   * @param _xerc20 The address of the XERC20
   * @return _result If the XERC20 is registered
   */

  function isRegisteredXERC20(address _xerc20) external view returns (bool _result) {
    _result = _isRegisteredXERC20(_xerc20);
  }

    /**
   * @notice Returns if a lockbox is registered
   *
   * @param _lockbox The address of the lockbox
   * @return _result If the lockbox is registered
   */

  function isRegisteredLockbox(address _lockbox) external view returns (bool _result) {
    _result = _isRegisteredLockbox(_lockbox);
  }

  /**
  * @notice Gets the lockbox that is registered to an XERC20
  *
  * @param _xerc20 The address of the XERC20
  * @return _lockbox The address of the lockbox
 */

  function lockboxRegistry(address _xerc20) external view returns (address _lockbox) {
    _lockbox = _getLockboxForXERC20(_xerc20);
  }

    /**
  * @notice Gets the lockbox that is registered to an XERC20
  *
  * @param _xerc20 The address of the XERC20
  * @return _lockbox The address of the lockbox
 */

  function _getLockboxForXERC20(address _xerc20) internal view returns (address _lockbox) {
    _lockbox = _lockboxRegistry[_xerc20];
    if (_lockbox == address(0) && address(OLD_FACTORY)  != address(0)) {
      _lockbox = OLD_FACTORY.lockboxRegistry(_xerc20);
    }
  }

  /**
  * @notice Returns if an XERC20 is in a registry
  *
  * @param _xerc20 The address of the XERC20
  * @return _result If the XERC20 is in the registry
   */

  function _isRegisteredXERC20(address _xerc20) internal view returns (bool _result) {
    _result = EnumerableSet.contains(_xerc20RegistryArray, _xerc20) || (address(OLD_FACTORY) != address(0) && OLD_FACTORY.isRegisteredXERC20(_xerc20));
  }

    /**
  * @notice Returns if an lockbox is in a registry
  *
  * @param _lockbox The address of the lockbox
  * @return _result If the lockbox is in the registry
   */

  function _isRegisteredLockbox(address _lockbox) internal view returns (bool _result) {
    if (EnumerableSet.contains(_lockboxRegistryArray, _lockbox)) {
      _result = true;
    } else if (address(OLD_FACTORY) != address(0)) {
      try OLD_FACTORY.isRegisteredLockbox(_lockbox) returns (bool _isRegistered) {
        _result = _isRegistered;
      } catch {
        // If the function fails then we are going to the first factory where the function does not exist
        // Get the xerc20 of the lockbox and check in the old factory if there is a lockbox registered to it
        address _xerc20 = address(XERC20Lockbox(payable(_lockbox)).XERC20());

        _result = OLD_FACTORY.lockboxRegistry(_xerc20) == _lockbox;
      }
      
    }
  }

    /**
   * @notice Loops through an EnumerableSet
   *
   * @param _start The start of the loop
   * @param _amount The amount of indexes to loop through
   * @return _result All the values from start to start + amount
   */

  function _getRegisteredSet(uint256 _start, uint256 _amount, EnumerableSet.AddressSet storage _set)
    internal
    view
    returns (address[] memory _result)
  {
    uint256 _length = EnumerableSet.length(_set);
    if (_amount > _length - _start) {
      _amount = _length - _start;
    }

    _result = new address[](_amount);
    uint256 _index;
    while (_index < _amount) {
      _result[_index] = EnumerableSet.at(_set, _start + _index);

      unchecked {
        ++_index;
      }
    }
  }

  /**
   * @notice Deploys an XERC20 contract using CREATE3
   * @dev _limits and _minters must be the same length
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   * @param _minterLimits The array of limits that you are adding (optional, can be an empty array)
   * @param _burnerLimits The array of limits that you are adding (optional, can be an empty array)
   * @param _bridges The array of burners that you are adding (optional, can be an empty array)
   */

  function _deployXERC20(
    string memory _name,
    string memory _symbol,
    uint256[] memory _minterLimits,
    uint256[] memory _burnerLimits,
    address[] memory _bridges
  ) internal returns (address _xerc20) {
    uint256 _bridgesLength = _bridges.length;
    if (_minterLimits.length != _bridgesLength || _burnerLimits.length != _bridgesLength) {
      revert IXERC20Factory_InvalidLength();
    }
    bytes32 _salt = keccak256(abi.encodePacked(_name, _symbol, msg.sender));
    bytes memory _creation = type(XERC20).creationCode;
    bytes memory _bytecode = abi.encodePacked(_creation, abi.encode(_name, _symbol, address(this)));

    _xerc20 = CREATE3.deploy(_salt, _bytecode, 0);

    EnumerableSet.add(_xerc20RegistryArray, _xerc20);

    for (uint256 _i; _i < _bridgesLength; ++_i) {
      XERC20(_xerc20).setLimits(_bridges[_i], _minterLimits[_i], _burnerLimits[_i]);
    }

    XERC20(_xerc20).transferOwnership(msg.sender);
  }

  function _deployLockbox(
    address _xerc20,
    address _baseToken,
    bool _isNative
  ) internal returns (address payable _lockbox) {
    bytes32 _salt = keccak256(abi.encodePacked(_xerc20, _baseToken, msg.sender));
    bytes memory _creation = type(XERC20Lockbox).creationCode;
    bytes memory _bytecode = abi.encodePacked(_creation, abi.encode(_xerc20, _baseToken, _isNative));

    _lockbox = payable(CREATE3.deploy(_salt, _bytecode, 0));

    XERC20(_xerc20).setLockbox(address(_lockbox));
    EnumerableSet.add(_lockboxRegistryArray, _lockbox);
    _lockboxRegistry[_xerc20] = _lockbox;
  }
}
