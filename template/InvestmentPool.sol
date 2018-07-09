pragma solidity ^0.4.23;

import "./CappedInvestmentPool.sol";
import "./TimedInvestmentPool.sol";
import "./CancellableInvestmentPool.sol";
import "./RefundableInvestmentPool.sol";
//#if D_WHITELIST
import "./WhitelistedInvestmentPool.sol";
//#endif


contract InvestmentPool is RefundableInvestmentPool
, CappedInvestmentPool
, TimedInvestmentPool
, CancellableInvestmentPool
//#if D_WHITELIST
, WhitelistedInvestmentPool
//#endif
{
    constructor(
        address _owner,
        address _investmentAddress
    )
        public
        BaseInvestmentPool(_owner, _investmentAddress)
        RefundableInvestmentPool(D_SOFT_CAP_WEI)
        CappedInvestmentPool(D_HARD_CAP_WEI)
        TimedInvestmentPool(D_START_TIME, D_END_TIME)
        CancellableInvestmentPool()
    {
        require(softCap < hardCap, "soft cap should be less than hard cap");
    }

    function cancel() public onlyOwner {
        require(softCapReached() && hasEnded(), "pool already reached soft cap before end time");
        super.cancel();
    }
}
