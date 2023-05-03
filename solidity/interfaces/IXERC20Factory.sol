// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

interface IXERC20Factory {
  /**
   * @notice Reverts when a contract is tring to deploy to an address that is already in use
   */

  error IXERC20Factory_AlreadyDeployed();

  /**
   * @notice Reverts when the caller is not able to deploy
   */

  error IXERC20Factory_CantDeploy();

  /**
   * @notice Deploys an XERC20 contract using CREATE2
   *
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   * @param _id The id of the NFT that manages the parameters
   */

  function deploy(string memory _name, string memory _symbol, uint256 _id) external returns (address _xerc20);
}
