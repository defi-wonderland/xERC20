// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {Test} from 'forge-std/Test.sol';
import {XERC20Factory, IXERC20Factory} from '../../contracts/XERC20Factory.sol';
import {Script} from 'forge-std/Script.sol';

contract ScriptingLibrary {
  function stringToUint(string memory s) public pure returns (uint256) {
    bytes memory b = bytes(s);
    uint256 result = 0;
    for (uint256 i = 0; i < b.length; i++) {
      uint256 c = uint256(uint8(b[i]));
      if (c >= 48 && c <= 57) {
        result = result * 10 + (c - 48);
      }
    }
    return result;
  }

  function addressToString(address _address) public pure returns (string memory) {
    bytes32 _bytes = bytes32(uint256(uint160(_address)));
    bytes memory HEX = '0123456789abcdef';
    bytes memory _string = new bytes(42);
    _string[0] = '0';
    _string[1] = 'x';
    for (uint256 i = 0; i < 20; i++) {
      _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
      _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
    }
    return string(_string);
  }

  function getAddress(bytes memory _bytecode, bytes32 _salt, address _sender) public pure returns (address) {
    bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), _sender, _salt, keccak256(_bytecode)));
    return address(uint160(uint256(hash)));
  }

  function fromHexChar(uint8 c) public pure returns (uint8) {
    if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
      return c - uint8(bytes1('0'));
    }
    if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
      return 10 + c - uint8(bytes1('a'));
    }
    if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
      return 10 + c - uint8(bytes1('A'));
    }
    return 0;
  }

  function hexStringToAddress(string memory s) public pure returns (bytes memory) {
    bytes memory ss = bytes(s);
    require(ss.length % 2 == 0); // length must be even
    bytes memory r = new bytes(ss.length/2);
    for (uint256 i = 0; i < ss.length / 2; ++i) {
      r[i] = bytes1(fromHexChar(uint8(ss[2 * i])) * 16 + fromHexChar(uint8(ss[2 * i + 1])));
    }

    return r;
  }

  function toAddress(string memory s) public pure returns (address) {
    bytes memory _bytes = hexStringToAddress(s);
    require(_bytes.length >= 1 + 20, 'toAddress_outOfBounds');
    address tempAddress;

    assembly {
      tempAddress := div(mload(add(add(_bytes, 0x20), 1)), 0x1000000000000000000000000)
    }

    return tempAddress;
  }
}
