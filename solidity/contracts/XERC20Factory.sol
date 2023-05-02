// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {XERC20} from 'contracts/XERC20.sol';
import {IXERC20Factory} from 'interfaces/IXERC20Factory.sol';

contract XERC20Factory is IXERC20Factory {
  /**
   * @notice Deploys an XERC20 contract using CREATE2
   *
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   */

  function deploy(string memory _name, string memory _symbol) public returns (address _xerc20) {
    bytes32 _salt = keccak256(abi.encodePacked(_name, _symbol, msg.sender));
    bytes memory _creation = type(XERC20).creationCode;
    bytes memory _bytecode = abi.encodePacked(_creation, abi.encode(_name, _symbol));

    assembly {
      _xerc20 := create2(0, add(_bytecode, 0x20), mload(_bytecode), _salt)
    }

    if (_xerc20 == address(0)) revert IXERC20Factory_AlreadyDeployed();
  }
}
