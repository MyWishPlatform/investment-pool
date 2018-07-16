pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


/**
 * @title MinRestrictedInvestmentPool
 * @dev The contract extends BaseInvestmentPool and adds additional functionality:
 *      investors can't send to the contract less than specified min amount in one transaction.
 */
contract MinRestrictedInvestmentPool is BaseInvestmentPool {
  /**
   * @notice min wei amount than can be contributed in one transaction.
   */
  uint public minInvestment;

  /**
   * @param _minInvestment min wei amount than can be contributed in one transaction.
   */
  constructor(uint _minInvestment) public {
    minInvestment = _minInvestment;
  }

  /**
   * @notice validates investor's transactions and contract state before applying investors funds.
   */
  function _preValidateInvest(address _beneficiary, uint _amount) internal {
    super._preValidateInvest(_beneficiary, _amount);
    require(_amount >= minInvestment, "too low value");
  }
}
