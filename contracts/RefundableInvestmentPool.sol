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
   * @notice emitted when investor takes him funds back.
   *
   * @param investor  investor address.
   * @param amount    wei amount.
   */
  event Refund(address indexed investor, uint amount);

  /**
   * @notice  user can refund his money if contract has been cancelled
   *          or time was out and funds has not been sent to ICO.
   */
  function claimRefund() external nonReentrant {
    require(investments[msg.sender] != 0, "you are not investor");
    require(!isFinalized, "funds already sent to ICO");
    require(hasEnded() || isCancelled, "contract has not ended and has not cancelled");
    address investor = msg.sender;
    uint amount = investments[investor];
    investor.transfer(amount);
    delete investments[investor];
    emit Refund(investor, amount);
  }
}
