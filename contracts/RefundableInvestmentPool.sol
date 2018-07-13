pragma solidity ^0.4.23;

import "./CancellableInvestmentPool.sol";
import "./TimedInvestmentPool.sol";


contract RefundableInvestmentPool is CancellableInvestmentPool, TimedInvestmentPool {
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
