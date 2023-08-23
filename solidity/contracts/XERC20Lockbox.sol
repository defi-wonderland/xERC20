// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {IXERC20} from 'interfaces/IXERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/math/SafeCast.sol';
import {IXERC20Lockbox} from 'interfaces/IXERC20Lockbox.sol';
import {IAllowanceTransfer} from 'permit2/src/interfaces/IAllowanceTransfer.sol';
import {IPermit2} from 'permit2/src/interfaces/IPermit2.sol';

contract XERC20Lockbox is IXERC20Lockbox {
  using SafeERC20 for IERC20;
  using SafeCast for uint256;

  /**
   * @notice The XERC20 token of this contract
   */
  IXERC20 public immutable XERC20;

  /**
   * @notice The ERC20 token of this contract
   */
  IERC20 public immutable ERC20;

  /**
   * @notice Whether the ERC20 token is the native gas token of this chain
   */

  bool public immutable IS_NATIVE;

  /**
   * @notice Permit2 address
   */

  IPermit2 public immutable PERMIT2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);

  /**
   * @notice Constructor
   *
   * @param _xerc20 The address of the XERC20 contract
   * @param _erc20 The address of the ERC20 contract
   */

  constructor(address _xerc20, address _erc20, bool _isNative) {
    XERC20 = IXERC20(_xerc20);
    ERC20 = IERC20(_erc20);
    IS_NATIVE = _isNative;
  }

  /**
   * @notice Deposit native tokens into the lockbox
   */

  function deposit() public payable {
    if (!IS_NATIVE) revert IXERC20Lockbox_NotNative();
    XERC20.mint(msg.sender, msg.value);

    emit Deposit(msg.sender, msg.value);
  }

  /**
   * @notice Deposit ERC20 tokens into the lockbox
   *
   * @param _amount The amount of tokens to deposit
   */

  function deposit(uint256 _amount) external {
    if (IS_NATIVE) revert IXERC20Lockbox_Native();

    ERC20.safeTransferFrom(msg.sender, address(this), _amount);
    XERC20.mint(msg.sender, _amount);

    emit Deposit(msg.sender, _amount);
  }

  /**
   * @notice Deposit ERC20 tokens into the lockbox using Permit2
   *
   * @param _amount The amount of tokens to deposit
   * @param _owner The owner of the tokens being deposited
   */

  function depositWithPermitAllowance(
    uint256 _amount,
    address _owner,
    IAllowanceTransfer.PermitSingle calldata _permit,
    bytes calldata signature
  ) external {
    if (IS_NATIVE) revert IXERC20Lockbox_Native();

    PERMIT2.permit(
      _owner,
      _permit,
      signature
    );

    PERMIT2.transferFrom(_owner, address(this), _amount.toUint160(), address(ERC20));
    XERC20.mint(_owner, _amount);

    emit Deposit(_owner, _amount);
  }

  /**
   * @notice Withdraw ERC20 tokens from the lockbox
   *
   * @param _amount The amount of tokens to withdraw
   */

  function withdraw(uint256 _amount) external {
    XERC20.burn(msg.sender, _amount);

    if (IS_NATIVE) {
      (bool _success,) = payable(msg.sender).call{value: _amount}('');
      if (!_success) revert IXERC20Lockbox_WithdrawFailed();
    } else {
      ERC20.safeTransfer(msg.sender, _amount);
    }

    emit Withdraw(msg.sender, _amount);
  }

  receive() external payable {
    deposit();
  }
}
