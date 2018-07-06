pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


contract CappedInvestmentPool is BaseInvestmentPool {
    uint hardCap;

    constructor(uint _hardCap) public {
        hardCap = _hardCap;
    }

    function hardCapReached() public view returns (bool) {
        return weiRaised >= hardCap;
    }

    function _preValidateInvest(address _beneficiary, uint _amount) internal {
        super._preValidateInvest(_beneficiary, _amount);
        require(!hardCapReached(), "hard cap already reached");
        require(weiRaised.add(_amount) <= hardCap, "cannot invest more than hard cap");
    }
}
