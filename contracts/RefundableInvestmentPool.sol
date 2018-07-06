pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


contract RefundableInvestmentPool is BaseInvestmentPool {
    uint softCap;

    constructor(uint _softCap) public {
        softCap = _softCap;
    }

    function softCapReached() public view returns (bool) {
        return weiRaised >= softCap;
    }
}
