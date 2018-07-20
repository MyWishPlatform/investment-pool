pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


/**
 * @title MaxRestrictedInvestmentPool
 * @dev The contract extends BaseInvestmentPool and adds additional functionality:
 *      investors can't send to the contract more than specified max amount in one transaction.
 */
contract MaxRestrictedInvestmentPool is BaseInvestmentPool {
  /**
   * @notice max wei amount than can be contributed in one transaction.
   */
  uint public maxInvestment;

  /**
   * @param _maxInvestment max wei amount than can be contributed in one transaction.
   */
  constructor(uint _maxInvestment) public {
    maxInvestment = _maxInvestment;
  }

  /**
   * @notice validates investor's transactions and contract state before applying investors funds.
   */
  function _preValidateInvest(address _beneficiary, uint _amount) internal {
    super._preValidateInvest(_beneficiary, _amount);
    require(_amount <= maxInvestment, "too high value");
  }
}
