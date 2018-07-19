pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


/**
 * @title CancellableInvestmentPool
 * @dev The contract extends BaseInvestmentPool and adds additional functionality: owner can cancel fundraising.
 */
contract CancellableInvestmentPool is BaseInvestmentPool {
  /**
   * @notice is contract owner cancelled fundraising.
   */
  bool public isCancelled;

  /**
   * @notice emitted when contract owner cancelled fundraising.
   */
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
   * @notice validates contract state before applying users funds.
   */
  function _preValidateInvest(address _beneficiary, uint _amount) internal {
    super._preValidateInvest(_beneficiary, _amount);
    require(!isCancelled, "contract is already cancelled");
  }
}
