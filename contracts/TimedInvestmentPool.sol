pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


contract TimedInvestmentPool is BaseInvestmentPool {
  uint public startTime;
  uint public endTime;

  constructor(uint _startTime, uint _endTime) public {
    require(_startTime < _endTime, "start time should be before end time");
    startTime = _startTime;
    endTime = _endTime;
  }

  /**
   * @return start time has already come
   */
  function hasStarted() public view returns (bool) {
    return now >= startTime;
  }

  /**
   * @return end time has not yet come
   */
  function hasEnded() public view returns (bool) {
    return now >= endTime;
  }

  /**
   * @notice validates investor's transactions and contract state before applying investors funds.
   */
  function _preValidateInvest(address _beneficiary, uint _amount) internal {
    super._preValidateInvest(_beneficiary, _amount);
    require(hasStarted(), "contract is not yet started");
    require(!hasEnded(), "contract is already ended");
  }

  /**
   * @notice validates transaction before sending funds to ICO.
   */
  function _preValidateFinalization() internal {
    super._preValidateFinalization();
    require(!hasEnded(), "time is out");
  }
}
