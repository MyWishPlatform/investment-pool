pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


contract TimedInvestmentPool is BaseInvestmentPool {
    uint public startTime;
    uint public endTime;

    constructor(uint _startTime, uint _endTime) public {
        require(_startTime < _endTime, "start time should be before end time");
        startTime = _startTime;
        endTime = _endTime;
    }

    function hasStarted() public view returns (bool) {
        return now >= startTime;
    }

    function hasEnded() public view returns (bool) {
        return now > endTime;
    }
}
