// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import {IXERC20Registry} from '../interfaces/IXERC20Registry.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract XERC20Registry is IXERC20Registry, Ownable {
  /**
   * @notice Address of the xerc20 maps to its data
   */
  mapping(address _xerc20 => XERC20Data _data) public xerc20Data;

  /**
   * @notice Address of the erc20 maps to its corresponding xerc20
   */
  mapping(address _erc20 => address _xerc20) public erc20ToXERC20;

  /**
   * @notice Adds an XERC20 contract to the registry
   *
   * @dev This function reverts if the xerc20 is already added
   * @param _xerc20 The address of the xerc20 that you want to add
   * @param _erc20 The address of the erc20 that the xerc20 is connected to
   * @param _lockbox The address of the lockbox for that xerc20
   * @param _version The version of the xerc20
   */
  function addXERC20(address _xerc20, address _erc20, address _lockbox, string memory _version) external onlyOwner {
    xerc20Data[_xerc20] = XERC20Data(_erc20, _lockbox, _version, true);
    if (_erc20 != address(0)) erc20ToXERC20[_erc20] = _xerc20;
    emit XERC20Registry_XERC20Added(_xerc20, _erc20, _lockbox, _version);
  }

  /**
   * @notice Removes an XERC20 from the registry
   *
   * @param _xerc20 The address of the xerc20 to remove
   */
  function removeXERC20(address _xerc20) external onlyOwner {
    if (!xerc20Data[_xerc20].exists) revert XERC20Registry_InvalidAddress();
    address _erc20 = xerc20Data[_xerc20].erc20;

    delete xerc20Data[_xerc20];
    emit XERC20Registry_XERC20Removed(_xerc20);

    if (_erc20 != address(0)) {
      delete erc20ToXERC20[_erc20];
      emit XERC20Registry_ERC20MappingUpdated(address(0), _erc20);
    }
  }

  /**
   * @notice Updates the XERC20 connected to the ERC20
   *
   * @dev Removes the XERC20 that was connected to the ERC20
   * @param _xerc20 The address of the XERC20
   * @param _erc20 The address of the ERC20
   */
  function updateXERC20forERC20(address _xerc20, address _erc20) external onlyOwner {
    if (_erc20 == address(0) || xerc20Data[_xerc20].erc20 != _erc20) revert XERC20Registry_InvalidAddress();

    address _oldXERC20 = erc20ToXERC20[_erc20];
    if (_oldXERC20 != address(0)) {
      delete xerc20Data[_oldXERC20];
      emit XERC20Registry_XERC20Removed(_oldXERC20);
    }

    erc20ToXERC20[_erc20] = _xerc20;
    emit XERC20Registry_ERC20MappingUpdated(_xerc20, _erc20);
  }
}
