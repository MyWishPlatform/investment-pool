pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


contract MinRestrictedInvestmentPool is BaseInvestmentPool {
  uint public minInvestment;

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
