pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


contract CancellableInvestmentPool is BaseInvestmentPool {
    bool public isCancelled;
    event Cancelled();

    function cancel() public onlyOwner {
        require(!isCancelled, "pool is already cancelled");
        require(!isFinalized, "pool is finalized");
        isCancelled = true;
        emit Cancelled();
    }

    function finalize() public {
        require(!isCancelled, "pool is cancelled");
        super.finalize();
    }

    function _preValidateInvest(address _beneficiary, uint _amount) internal {
        super._preValidateInvest(_beneficiary, _amount);
        require(!isCancelled, "contract is already cancelled");
    }
}
