// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

interface IXERC20Factory {
  error IXERC20Factory_AlreadyDeployed();

  /**
   * @notice Deploys an XERC20 contract using CREATE2
   *
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   */

  function deploy(string memory _name, string memory _symbol) external returns (address _xerc20);
}
