pragma solidity ^0.4.23;

import "./MockERC20Crowdsale.sol";
import "./MockERC223Token.sol";


contract MockERC223Crowdsale is MockERC20Crowdsale {
  function _createTokenContract() internal returns (MockERC20Token) {
    return new MockERC223Token();
  }
}
