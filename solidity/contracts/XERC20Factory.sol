// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {XERC20, IXERC20} from 'contracts/XERC20.sol';
import {IXERC20Factory} from 'interfaces/IXERC20Factory.sol';
import {XERC20Lockbox} from 'contracts/XERC20Lockbox.sol';
import {CREATE3} from 'isolmate/utils/CREATE3.sol';

contract XERC20Factory is IXERC20Factory {
  // address maps to the index inside the array
  mapping(address => bool) public xerc20Registry;
  // address of the xerc20 maps to its corresponding lockbox
  mapping(address => address) public lockboxRegistry;

  address[] public lockboxRegistryArray;
  address[] public xerc20RegistryArray;

  /**
   * @notice Deploys an XERC20 contract using CREATE2
   * @dev _limits and _minters must be the same length
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   * @param _limits The array of limits that you are adding (optional, can be an empty array)
   * @param _minters The array of minters that you are adding (optional, can be an empty array)
   * @param _baseToken The address of the base ERC20 token if you are deploying a lockbox (optional, put address(0) if you dont want to deploy one)
   */

  function deploy(
    string memory _name,
    string memory _symbol,
    uint256[] memory _limits,
    address[] memory _minters,
    address _baseToken
  ) external returns (address _xerc20, address _lockbox) {
    _xerc20 = _deployXERC20(_name, _symbol, _limits, _minters);

    if (_baseToken != address(0)) {
      _lockbox = _deployLockbox(_xerc20, _baseToken);
    }
  }

  /**
   * @notice Deploys an XERC20Lockbox contract using CREATE3
   *
   * @param _xerc20 The address of the xerc20 that you want to deploy a lockbox for
   * @param _baseToken The address of the base token that you want to lock
   */

  function deployLockbox(address _xerc20, address _baseToken) external returns (address _lockbox) {
    if (_xerc20 == address(0) || _baseToken == address(0)) revert IXERC20Factory_TokenZeroAddress();
    if (XERC20(_xerc20).owner() != msg.sender) revert IXERC20Factory_NotOwner();
    if (lockboxRegistry[_xerc20] != address(0)) revert IXERC20Factory_LockboxAlreadyDeployed();

    _lockbox = _deployLockbox(_xerc20, _baseToken);
  }

  /**
   * @notice Deploys an XERC20 contract using CREATE3
   * @dev _limits and _minters must be the same length
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   * @param _limits The array of limits that you are adding (optional, can be an empty array)
   * @param _minters The array of minters that you are adding (optional, can be an empty array)
   */

  function _deployXERC20(
    string memory _name,
    string memory _symbol,
    uint256[] memory _limits,
    address[] memory _minters
  ) internal returns (address _xerc20) {
    bytes32 _salt = keccak256(abi.encodePacked(_name, _symbol, msg.sender));
    bytes memory _creation = type(XERC20).creationCode;
    bytes memory _bytecode = abi.encodePacked(_creation, abi.encode(_name, _symbol, msg.sender));

    _xerc20 = CREATE3.deploy(_salt, _bytecode, 0);

    xerc20RegistryArray.push(_xerc20);
    xerc20Registry[_xerc20] = true;

    // if the user inputs empty arrays we dont waste gas calling these functions
    if (_limits.length != _minters.length && _limits.length != 0) {
      XERC20(_xerc20).createLimits(_limits, _minters);
    }
  }

  function _deployLockbox(address _xerc20, address _baseToken) internal returns (address _lockbox) {
    bytes32 _salt = keccak256(abi.encodePacked(_xerc20, _baseToken, msg.sender));
    bytes memory _creation = type(XERC20Lockbox).creationCode;
    bytes memory _bytecode = abi.encodePacked(_creation, abi.encode(_xerc20, _baseToken));

    _lockbox = CREATE3.deploy(_salt, _bytecode, 0);

    lockboxRegistryArray.push(_lockbox);
    lockboxRegistry[_xerc20] = _lockbox;
  }
}
