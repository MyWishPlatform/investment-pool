pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


contract SoftCappedInvestmentPool is BaseInvestmentPool {
  uint softCap;

  constructor(uint _softCap) public {
    softCap = _softCap;
  }

  /**
   * @return is soft cap reached
   */
  function softCapReached() public view returns (bool) {
    return weiRaised >= softCap;
  }

  /**
   * @notice validates transaction before sending funds to ICO.
   */
  function _preValidateFinalization() internal {
    super._preValidateFinalization();
    require(softCapReached(), "soft cap did not reached yet");
  }
}
