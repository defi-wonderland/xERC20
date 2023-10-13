// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

interface IXERC20Registry {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Emitted when a new XERC20 is added
   *
   * @param _xerc20 The address of the xerc20 that was added
   * @param _erc20 The address of the erc20 that the xerc20 is connected to
   * @param _lockbox The address of the lockbox for that xerc20
   * @param _version The version of the xerc20
   */
  // solhint-disable-next-line
  event XERC20Registry_XERC20Added(address _xerc20, address _erc20, address _lockbox, string _version);

  /**
   * @notice Emitted when a XERC20 is removed
   *
   * @param _xerc20 The address of the xerc20 that was removed
   */
  // solhint-disable-next-line
  event XERC20Registry_XERC20Removed(address _xerc20);

  /**
   * @notice Emitted when the XERC20 connected to an ERC20 is updated
   *
   * @param _xerc20 The address of the xerc20 that was updated
   * @param _erc20 The address of the erc20 that the xerc20 is connected to
   */
  // solhint-disable-next-line
  event XERC20Registry_ERC20MappingUpdated(address _xerc20, address _erc20);

  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Emitted when the address provided is invalid
   */
  error XERC20Registry_InvalidAddress();

  /*///////////////////////////////////////////////////////////////
                              STRUCTS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Data for a registered XERC20
   *
   * @param erc20 The address of the erc20 that the xerc20 is connected to
   * @param lockbox The address of the lockbox for that xerc20
   * @param version The version of the xerc20
   * @param exists Whether or not the xerc20 exists
   */
  struct XERC20Data {
    address erc20;
    address lockbox;
    string version;
    bool exists;
  }

  /*///////////////////////////////////////////////////////////////
                              FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the data for an XERC20
   *
   * @param _erc20 The address of the _ that the xerc20 is connected to
   * @param _lockbox The address of the lockbox for that xerc20
   * @param _version The version of the xerc20
   * @param _exists Whether or not the xerc20 exists
   */
  function xerc20Data(address _xerc20)
    external
    view
    returns (address _erc20, address _lockbox, string memory _version, bool _exists);

  /**
   * @notice Returns the address of the XERC20 connected to the ERC20
   *
   * @param _erc20 The address of the erc20
   */
  function erc20ToXERC20(address _erc20) external view returns (address _xerc20);

  /**
   * @notice Adds an XERC20 contract to the registry
   *
   * @param _xerc20 The address of the xerc20 to add
   * @param _erc20 The address of the erc20 that the xerc20 is connected to
   * @param _lockbox The address of the lockbox for that xerc20
   * @param _version The version of the xerc20
   */

  function addXERC20(address _xerc20, address _erc20, address _lockbox, string memory _version) external;

  /**
   * @notice Removes an XERC20 from the registry
   *
   * @param _xerc20 The address of the xerc20 to remove
   */
  function removeXERC20(address _xerc20) external;

  /**
   * @notice Updates the XERC20 connected to the ERC20
   *
   * @param _xerc20 The address of the XERC20
   * @param _erc20 The address of the ERC20
   */
  function updateXERC20forERC20(address _xerc20, address _erc20) external;
}
