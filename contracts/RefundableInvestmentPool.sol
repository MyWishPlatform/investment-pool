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
  bool public isIcoRefunded;

  /**
   * @notice emitted when investor takes him funds back.
   *
   * @param investor  investor address.
   * @param amount    wei amount.
   */
  event Refund(address indexed investor, uint amount);

  /**
   * @notice fallback function applying funds from investors or ICO.
   */
  function() external payable {
    if (msg.sender == investmentAddress) {
      isIcoRefunded = true;
    } else {
      invest(msg.sender);
    }
  }

  /**
   * @notice  user can refund his money if contract has been cancelled
   *          or time was out and funds has not been sent to ICO.
   */
  function claimRefund() external nonReentrant {
    require(investments[msg.sender] != 0, "you are not investor");
    require(isCancelled || (!isFinalized && hasEnded()) || isIcoRefunded,
      "contract has not ended, not cancelled and ico did not refunded");
    address investor = msg.sender;
    uint amount = investments[investor];
    investor.transfer(amount);
    delete investments[investor];
    emit Refund(investor, amount);
  }
}
