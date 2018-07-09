pragma solidity ^0.4.23;

import "./HardCappedInvestmentPool.sol";
import "./TimedInvestmentPool.sol";
import "./CancellableInvestmentPool.sol";
import "./RefundableInvestmentPool.sol";
//#if D_WHITELIST
import "./WhitelistedInvestmentPool.sol";
//#endif
//#if D_MIN_VALUE_WEI > 0
import "./MinRestrictedInvestmentPool.sol";
//#endif
//#if D_MAX_VALUE_WEI > 0
import "./MaxRestrictedInvestmentPool.sol";
//#endif


contract InvestmentPool is RefundableInvestmentPool
, HardCappedInvestmentPool
, TimedInvestmentPool
, CancellableInvestmentPool
//#if D_WHITELIST
, WhitelistedInvestmentPool
//#endif
//#if D_MIN_VALUE_WEI > 0
, MinRestrictedInvestmentPool
//#endif
//#if D_MAX_VALUE_WEI > 0
, MaxRestrictedInvestmentPool
//#endif
{
    constructor(
        address _owner,
        address _investmentAddress
    )
        public
        BaseInvestmentPool(_owner, _investmentAddress)
        RefundableInvestmentPool(D_SOFT_CAP_WEI)
        HardCappedInvestmentPool(D_HARD_CAP_WEI)
        TimedInvestmentPool(D_START_TIME, D_END_TIME)
        //#if D_MIN_VALUE_WEI > 0
        MinRestrictedInvestmentPool(D_MIN_VALUE_WEI)
        //#endif
        //#if D_MAX_VALUE_WEI > 0
        MaxRestrictedInvestmentPool(D_MAX_VALUE_WEI)
        //#endif
    {
        require(softCap < hardCap, "soft cap should be less than hard cap");
    }

    function _preValidateCancellation() internal {
        super._preValidateCancellation();
        require(softCapReached() && hasEnded(), "pool already reached soft cap before end time");
    }
    //#if D_MIN_VALUE_WEI > 0

    function _preValidateFinalization() internal {
        super._preValidateFinalization();
        bool remainValue = hardCap.sub(weiRaised) < D_MIN_VALUE_WEI;
        require(remainValue);
    }
    //#endif
}
