pragma solidity ^0.4.23;

import "./CancellableInvestmentPool.sol";
import "./TimedInvestmentPool.sol";


/**
 * @title RefundableInvestmentPool
 * @dev The contract extends CancellableInvestmentPool and TimedInvestmentPool and adds additional functionality:
 *      investors can take their funds back if fundraising was cancelled or send time is over and funds was not be sent
 *      to the investment address.
 */
contract RefundableInvestmentPool is CancellableInvestmentPool, TimedInvestmentPool {
  /**
   * @notice is ICO returned funds.
   */
  bool public isInvestmentAddressRefunded;

  /**
   * @notice emitted when investor takes him funds back.
   *
   * @param investor  investor address.
   * @param amount    wei amount.
   */
  event Refund(address indexed investor, uint amount);

  event ClaimRefund(uint amount);

  bool private isRefundMode;

  /**
   * @notice fallback function applying funds from investors or ICO.
   */
  function() external payable {
    if (msg.sender == investmentAddress || isRefundMode) {
      isInvestmentAddressRefunded = true;
      emit ClaimRefund(msg.value);
    } else {
      invest(msg.sender);
    }
  }

  /**
   * Execute function on contract of investment address. It is for refund
   *
   * @param _data call data. For example: claimRefund() - 0xb5545a3c.
   */
  function executeOnInvestmentAddress(bytes _data)
    external
    payable
    onlyOwner
    nonReentrant
  {
    require(investmentAddress != address(0), "investment address did not set");
    isRefundMode = true;
    if (msg.value != 0) {
      investmentAddress.call.value(msg.value)(_data); // solium-disable-line security/no-call-value
    } else {
      investmentAddress.call(_data); // solium-disable-line security/no-low-level-calls
    }
    isRefundMode = false;
  }

  /**
   * @notice  user can refund his money if contract has been cancelled
   *          or time was out and funds has not been sent to ICO.
   */
  function claimRefund() external nonReentrant {
    require(investments[msg.sender] != 0, "you are not investor");
    require(isCancelled || (!isFinalized && hasEnded()) || isInvestmentAddressRefunded,
      "contract has not ended, not cancelled and ico did not refunded");
    address investor = msg.sender;
    uint amount = investments[investor];
    investor.transfer(amount);
    delete investments[investor];
    emit Refund(investor, amount);
  }
}
