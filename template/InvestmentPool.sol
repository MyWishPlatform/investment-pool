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
        uint _startTime,
        uint _endTime,
        uint _softCap,
        uint _hardCap,
        address _investmentAddress
    )
        public
        BaseInvestmentPool(_owner, _investmentAddress)
        RefundableInvestmentPool(_softCap)
        CappedInvestmentPool(_hardCap)
        TimedInvestmentPool(_startTime, _endTime)
        CancellableInvestmentPool()
    {
        require(_softCap < hardCap, "soft cap should be less than hard cap");
    }

    function cancel() public onlyOwner {
        require(softCapReached() && hasEnded(), "pool already reached soft cap before end time");
        super.cancel();
    }
}
