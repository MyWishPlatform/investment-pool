pragma solidity ^0.4.23;

import "./BaseERC20Crowdsale.sol";


contract MockVestingERC20Crowdsale is BaseERC20Crowdsale, Ownable {
  function releaseFirstHalfTokens() public {
    for (uint i = 0; i < investors.length; i++) {
      address investor = investors[i];
      uint amount = tokens[investor].div(2);
      if (amount != 0) {
        token.mint(investor, amount);
        tokens[investor] = tokens[investor].sub(amount);
      }
    }
  }

  function releaseSecondHalfTokens() public {
    for (uint i = 0; i < investors.length; i++) {
      _forwardTokens(investors[i], tokens[investors[i]]);
    }
  }
}
