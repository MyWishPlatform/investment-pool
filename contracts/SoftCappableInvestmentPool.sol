pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


contract SoftCappableInvestmentPool is BaseInvestmentPool {
    uint softCap;

    constructor(uint _softCap) public {
        softCap = _softCap;
    }

    function softCapReached() public view returns (bool) {
        return weiRaised >= softCap;
    }

    function _preValidateFinalization() internal {
        super._preValidateFinalization();
        require(softCapReached(), 'soft cap did not reached yet');
    }
}
