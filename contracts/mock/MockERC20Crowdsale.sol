pragma solidity ^0.4.23;

import "./BaseERC20Crowdsale.sol";


contract MockERC20Crowdsale is BaseERC20Crowdsale {
  function buyTokens(address _beneficiary) public payable {
    super.buyTokens(_beneficiary);
    _forwardTokens(_beneficiary, tokens[_beneficiary]);
  }
}
