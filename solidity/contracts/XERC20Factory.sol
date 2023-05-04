// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {XERC20, IXERC20} from 'contracts/XERC20.sol';
import {IXERC20Factory} from 'interfaces/IXERC20Factory.sol';

contract XERC20Factory is IXERC20Factory {
  // address maps to the index inside the array
  mapping(address => bool) public registry;
  address[] public registryArray;

  /**
   * @notice Deploys an XERC20 contract using CREATE2
   *
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   */

  function deploy(
    string memory _name,
    string memory _symbol,
    uint256[] memory _limits,
    address[] memory _minters,
    uint256[] memory _chainId
  ) public returns (address _xerc20) {
    // TODO: Make a better salt encoding as msg.sender is always going to be params contract
    bytes32 _salt = keccak256(abi.encodePacked(_name, _symbol, msg.sender));
    bytes memory _creation = type(XERC20).creationCode;
    bytes memory _bytecode = abi.encodePacked(_creation, abi.encode(_name, _symbol));
    assembly {
      _xerc20 := create2(0, add(_bytecode, 0x20), mload(_bytecode), _salt)
    }

    if (_xerc20 == address(0)) revert IXERC20Factory_AlreadyDeployed();
    registryArray.push(_xerc20);
    registry[_xerc20] = true;

    // if the user inputs empty arrays we dont waste gas calling these functions
    if (_limits.length != _minters.length && _limits.length == 0) {
      XERC20(_xerc20).createLimits(_limits, _minters);
    }

    if (_chainId.length != 0) {
      XERC20(_xerc20).createChainIds(_chainId);
    }

    XERC20(_xerc20).transferOwnership(msg.sender);
  }
}
