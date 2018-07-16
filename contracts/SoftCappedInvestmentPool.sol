pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


/**
 * @title SoftCappedInvestmentPool
 * @dev The contract extends BaseInvestmentPool and adds additional functionality:
 *      it's able to send funds to investment address only after specified soft cap is reached.
 */
contract SoftCappedInvestmentPool is BaseInvestmentPool {
  /**
   * @notice min wei amount needed to allow send it to investment address.
   */
  uint softCap;

  /**
   * @param _softCap min wei amount needed to allow send it to investment address.
   */
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
