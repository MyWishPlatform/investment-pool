pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


contract CancellableInvestmentPool is BaseInvestmentPool {
    bool public isCancelled;
    event Cancelled();

    function cancel() public onlyOwner {
        require(!isCancelled, "pool is already cancelled");
        _preValidateCancellation();
        isCancelled = true;
        emit Cancelled();
    }

    function _preValidateCancellation() internal {
        require(!isFinalized, "pool is finalized");
    }

    function _preValidateFinalization() internal {
        super._preValidateFinalization();
        require(!isCancelled, "pool is cancelled");
    }

    function _preValidateInvest(address _beneficiary, uint _amount) internal {
        super._preValidateInvest(_beneficiary, _amount);
        require(!isCancelled, "contract is already cancelled");
    }
}
