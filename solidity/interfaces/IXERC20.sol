// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

interface IXERC20 {
  /**
   * @notice Adds a minter to the allowlist
   *
   * @param _minter The address of the minter to give permissions to
   */

  function setMinter(address _minter) external;
}
