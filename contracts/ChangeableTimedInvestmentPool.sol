pragma solidity ^0.4.23;

import "./TimedInvestmentPool.sol";


contract ChangeableTimedInvestmentPool is TimedInvestmentPool {
  event TimesChanged(uint startTime, uint endTime, uint oldStartTime, uint oldEndTime);

  function setStartTime(uint _startTime) public onlyOwner {
    // only if InvestmentPool was not started
    require(now < startTime);
    // only move time to future
    require(_startTime > startTime);
    require(_startTime < endTime);
    emit TimesChanged(
      _startTime,
      endTime,
      startTime,
      endTime
    );
    startTime = _startTime;
  }

  function setEndTime(uint _endTime) public onlyOwner {
    // only if InvestmentPool was not ended
    require(now < endTime);
    // only if new end time in future
    require(now < _endTime);
    require(_endTime > startTime);
    emit TimesChanged(
      startTime,
      _endTime,
      startTime,
      endTime
    );
    endTime = _endTime;
  }

  function setTimes(uint _startTime, uint _endTime) public onlyOwner {
    require(_endTime > _startTime);
    uint oldStartTime = startTime;
    uint oldEndTime = endTime;
    bool changed = false;
    if (_startTime != oldStartTime) {
      require(_startTime > now);
      // only if InvestmentPool was not started
      require(now < oldStartTime);
      // only move time to future
      require(_startTime > oldStartTime);

      startTime = _startTime;
      changed = true;
    }
    if (_endTime != oldEndTime) {
      // only if InvestmentPool was not ended
      require(now < oldEndTime);
      // end time in future
      require(now < _endTime);

      endTime = _endTime;
      changed = true;
    }

    if (changed) {
      emit TimesChanged(
        startTime,
        _endTime,
        startTime,
        endTime
      );
    }
  }
}
