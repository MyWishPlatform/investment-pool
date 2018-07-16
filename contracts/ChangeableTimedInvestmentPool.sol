pragma solidity ^0.4.23;

import "./TimedInvestmentPool.sol";


/**
 * @title ChangeableTimedInvestmentPool
 * @dev The contract extends TimedInvestmentPool and adds additional functionality:
 *      owner can change start and end times.
 */
contract ChangeableTimedInvestmentPool is TimedInvestmentPool {
  /**
   * @notice emitted when contract owner shifted start or/and end time.
   *
   * @param startTime     new start time.
   * @param endTime       new end time.
   * @param oldStartTime  old start time.
   * @param oldEndTime    old end time.
   */
  event TimesChanged(uint startTime, uint endTime, uint oldStartTime, uint oldEndTime);

  /**
   * @notice shifts the start time when contract applies funds from investors.
   */
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

  /**
   * @notice shifts the end time when contract applies funds from investors.
   */
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

  /**
   * @notice shifts the time (start & end) when contract applies funds from investors.
   */
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
