pragma solidity ^0.4.23;


contract MockCustomCallsContract {
  bool public isCalledNonPayable;
  bool public isCalledPayable;
  bool public isCalledPayableRequiredFunds;
  bool public isCalledReturningFunds;

  function() external payable {}

  function payableCall() public payable {
    isCalledPayable = true;
  }

  function payableCallRequiresFunds() public payable {
    require(msg.value != 0);
    isCalledPayableRequiredFunds = true;
  }

  function nonPayableCall() public {
    isCalledNonPayable = true;
  }

  function returningFundsCall() public {
    isCalledReturningFunds = true;
    msg.sender.call.value(address(this).balance)(); // solium-disable-line security/no-call-value
  }
}
