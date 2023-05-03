// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {XERC20} from 'contracts/XERC20.sol';
import {IXERC20Factory} from 'interfaces/IXERC20Factory.sol';

contract XERC20Factory is IXERC20Factory {
  address public immutable PARAMETERS;

  constructor(address _parameters) {
    PARAMETERS = _parameters;
  }

  /**
   * @notice Deploys an XERC20 contract using CREATE2
   *
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   * @param _id The id of the NFT that manages the parameters
   */

  function deploy(string memory _name, string memory _symbol, uint256 _id) public returns (address _xerc20) {
    if (msg.sender != PARAMETERS) revert IXERC20Factory_CantDeploy();
    // TODO: Make a better salt encoding as msg.sender is always going to be params contract
    bytes32 _salt = keccak256(abi.encodePacked(_name, _symbol, msg.sender));
    bytes memory _creation = type(XERC20).creationCode;
    bytes memory _bytecode = abi.encodePacked(_creation, abi.encode(_name, _symbol, PARAMETERS, _id));
    assembly {
      _xerc20 := create2(0, add(_bytecode, 0x20), mload(_bytecode), _salt)
    }

    if (_xerc20 == address(0)) revert IXERC20Factory_AlreadyDeployed();
  }
}
