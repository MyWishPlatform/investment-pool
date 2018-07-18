pragma solidity ^0.4.23;


contract RefundVault {
  function() external payable {}

  function refund(address _recipient) {
    _recipient.call.value(address(this).balance)(); // solium-disable-line security/no-call-value
  }
}


contract MockRefundableCrowdsale {
  bool public isCalledRefund;

  RefundVault public vault;

  constructor() public {
    vault = new RefundVault();
  }

  function() external payable {
    vault.call.value(msg.value)();
    address(vault).call.value(address(this).balance)(); // solium-disable-line security/no-call-value
  }

  function refund() public {
    isCalledRefund = true;
    vault.refund(msg.sender);
//    msg.sender.call.value(address(this).balance)(); // solium-disable-line security/no-call-value
  }
}
