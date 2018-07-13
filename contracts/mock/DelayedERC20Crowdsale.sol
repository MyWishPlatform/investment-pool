pragma solidity ^0.4.23;

import "./BaseERC20Crowdsale.sol";


contract DelayedERC20Crowdsale is BaseERC20Crowdsale, Ownable {
  constructor(uint256 _rate) public BaseERC20Crowdsale(_rate) {}

  function finalize() public onlyOwner {
    for (uint i = 0; i < investors.length; i++) {
      _forwardTokens(investors[i], tokens[investors[i]]);
    }
  }
}
