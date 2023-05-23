// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {XERC20} from 'contracts/XERC20.sol';
import {IXERC20Factory} from 'interfaces/IXERC20Factory.sol';
import {XERC20Lockbox} from 'contracts/XERC20Lockbox.sol';
import {CREATE3} from 'isolmate/utils/CREATE3.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

contract XERC20Factory is IXERC20Factory {
  using EnumerableSet for EnumerableSet.AddressSet;

  /**
   * @notice Address of the xerc20 maps to the address of its lockbox if it has one
   */
  mapping(address => address) public lockboxRegistry;

  /**
   * @notice The set of registered lockboxes
   */
  EnumerableSet.AddressSet internal _lockboxRegistryArray;

  /**
   * @notice The set of registered XERC20 tokens
   */
  EnumerableSet.AddressSet internal _xerc20RegistryArray;

  /**
   * @notice Deploys an XERC20 contract using CREATE2
   * @dev _limits and _minters must be the same length
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   * @param _minterLimits The array of limits that you are adding (optional, can be an empty array)
   * @param _burnerLimits The array of limits that you are adding (optional, can be an empty array)
   * @param _bridges The array of bridges that you are adding (optional, can be an empty array)
   * @param _baseToken The address of the base ERC20 token if you are deploying a lockbox (optional, put address(0) if you dont want to deploy one)
   */

  function deploy(
    string memory _name,
    string memory _symbol,
    uint256[] memory _minterLimits,
    uint256[] memory _burnerLimits,
    address[] memory _bridges,
    address _baseToken
  ) external returns (address _xerc20, address _lockbox) {
    if (_baseToken != address(0)) {
      bytes32 _salt = keccak256(abi.encodePacked(_name, _symbol, msg.sender));
      address _preComputedXERC20 = CREATE3.getDeployed(_salt);
      _lockbox = _deployLockbox(_preComputedXERC20, _baseToken);
    }

    _xerc20 = _deployXERC20(_name, _symbol, _minterLimits, _burnerLimits, _bridges, _lockbox);

    emit XERC20Deployed(_xerc20, _lockbox);
  }

  /**
   * @notice Deploys an XERC20Lockbox contract using CREATE3
   *
   * @param _xerc20 The address of the xerc20 that you want to deploy a lockbox for
   * @param _baseToken The address of the base token that you want to lock
   */

  function deployLockbox(address _xerc20, address _baseToken) external returns (address _lockbox) {
    if (_baseToken == address(0) || !EnumerableSet.contains(_xerc20RegistryArray, _xerc20)) {
      revert IXERC20Factory_BadTokenAddress();
    }
    if (XERC20(_xerc20).owner() != msg.sender) revert IXERC20Factory_NotOwner();
    if (lockboxRegistry[_xerc20] != address(0)) revert IXERC20Factory_LockboxAlreadyDeployed();

    _lockbox = _deployLockbox(_xerc20, _baseToken);

    emit LockboxDeployed(_lockbox);
  }

  /**
   * @notice Checks if an XERC20 is registered
   *
   * @param _xerc20 The address of the xerc20 that you want to check
   * @return _result True if the xerc20 is registered, false if not
   */

  function isXERC20(address _xerc20) external view returns (bool _result) {
    _result = EnumerableSet.contains(_xerc20RegistryArray, _xerc20);
  }

  /**
   * @notice Loops through the xerc20RegistryArray
   *
   * @param _start The start of the loop
   * @param _amount The end of the loop
   * @return _lockboxes The array of xerc20s from the start to start + amount
   */

  function getRegisteredLockboxes(uint256 _start, uint256 _amount) public view returns (address[] memory _lockboxes) {
    uint256 _length = EnumerableSet.length(_lockboxRegistryArray);
    if (_amount > _length - _start) {
      _amount = _length - _start;
    }

    _lockboxes = new address[](_amount);
    uint256 _index;
    while (_index < _amount) {
      _lockboxes[_index] = EnumerableSet.at(_lockboxRegistryArray, _start + _index);

      unchecked {
        ++_index;
      }
    }
  }

  /**
   * @notice Loops through the xerc20RegistryArray
   *
   * @param _start The start of the loop
   * @param _amount The amount of xerc20s to loop through
   * @return _xerc20s The array of xerc20s from the start to start + amount
   */

  function getRegisteredXERC20(uint256 _start, uint256 _amount) public view returns (address[] memory _xerc20s) {
    uint256 _length = EnumerableSet.length(_xerc20RegistryArray);
    if (_amount > _length - _start) {
      _amount = _length - _start;
    }

    _xerc20s = new address[](_amount);
    uint256 _index;
    while (_index < _amount) {
      _xerc20s[_index] = EnumerableSet.at(_xerc20RegistryArray, _start + _index);

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
   * @param _lockbox The address of the lockbox (If no lockbox is deployed will be address(0))
   */

  function _deployXERC20(
    string memory _name,
    string memory _symbol,
    uint256[] memory _minterLimits,
    uint256[] memory _burnerLimits,
    address[] memory _bridges,
    address _lockbox
  ) internal returns (address _xerc20) {
    bytes32 _salt = keccak256(abi.encodePacked(_name, _symbol, msg.sender));
    bytes memory _creation = type(XERC20).creationCode;
    bytes memory _bytecode = abi.encodePacked(_creation, abi.encode(_name, _symbol, address(this)));

    _xerc20 = CREATE3.deploy(_salt, _bytecode, 0);

    EnumerableSet.add(_xerc20RegistryArray, _xerc20);

    // if the user inputs empty arrays we dont waste gas calling these functions
    if (_minterLimits.length != 0) {
      XERC20(_xerc20).createMinterLimits(_minterLimits, _bridges);
    }

    if (_burnerLimits.length != 0) {
      XERC20(_xerc20).createBurnerLimits(_burnerLimits, _bridges);
    }

    XERC20(_xerc20).setLockbox(_lockbox);
    XERC20(_xerc20).transferOwnership(msg.sender);
  }

  function _deployLockbox(address _xerc20, address _baseToken) internal returns (address _lockbox) {
    bytes32 _salt = keccak256(abi.encodePacked(_xerc20, _baseToken, msg.sender));
    bytes memory _creation = type(XERC20Lockbox).creationCode;
    bytes memory _bytecode = abi.encodePacked(_creation, abi.encode(_xerc20, _baseToken));

    _lockbox = CREATE3.deploy(_salt, _bytecode, 0);

    EnumerableSet.add(_lockboxRegistryArray, _lockbox);
    lockboxRegistry[_xerc20] = _lockbox;
  }
}
