pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


contract MaxRestrictedInvestmentPool is BaseInvestmentPool {
  uint public maxInvestment;

  constructor(uint _maxInvestment) public {
    maxInvestment = _maxInvestment;
  }

  function _preValidateInvest(address _beneficiary, uint _amount) internal {
    super._preValidateInvest(_beneficiary, _amount);
    require(_amount <= maxInvestment, "too high value");
  }
}
