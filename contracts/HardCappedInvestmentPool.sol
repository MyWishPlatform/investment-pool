pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


/**
 * @title HardCappedInvestmentPool
 * @dev The contract extends BaseInvestmentPool and adds additional functionality:
 *      contract can't raise more funds than specified cap.
 */
contract HardCappedInvestmentPool is BaseInvestmentPool {
  /**
   * @notice max wei amount that can be raised on the contract.
   */
  uint hardCap;

  /**
   * @param _hardCap max wei amount that can be raised on the contract.
   */
  constructor(uint _hardCap) public {
    hardCap = _hardCap;
  }

  /**
   * @return is hard cap reached.
   */
  function hardCapReached() public view returns (bool) {
    return weiRaised >= hardCap;
  }

  /**
   * @notice validates investor's transactions and contract state before applying investors funds.
   */
  function _preValidateInvest(address _beneficiary, uint _amount) internal {
    super._preValidateInvest(_beneficiary, _amount);
    require(!hardCapReached(), "hard cap already reached");
    require(weiRaised.add(_amount) <= hardCap, "cannot invest more than hard cap");
  }
}
