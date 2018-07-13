pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


contract CancellableInvestmentPool is BaseInvestmentPool {
  bool public isCancelled;

  event Cancelled();

  /**
   * @notice sets contract to cancelled state. No one can contribute funds to contract ins this state.
   */
  function cancel() public onlyOwner {
    require(!isCancelled, "pool is already cancelled");
    _preValidateCancellation();
    isCancelled = true;
    emit Cancelled();
  }

  /**
   * @notice validates contract's state before cancellation.
   */
  function _preValidateCancellation() internal {
    require(!isFinalized, "pool is finalized");
  }

  /**
   * @notice validates contract's state before finalization.
   */
  function _preValidateFinalization() internal {
    super._preValidateFinalization();
    require(!isCancelled, "pool is cancelled");
  }

  /**
   * @notice validates contract's state before applying users funds.
   */
  function _preValidateInvest(address _beneficiary, uint _amount) internal {
    super._preValidateInvest(_beneficiary, _amount);
    require(!isCancelled, "contract is already cancelled");
  }
}
