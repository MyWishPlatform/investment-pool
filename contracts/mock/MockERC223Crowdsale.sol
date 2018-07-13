pragma solidity ^0.4.23;

import "./MockERC20Crowdsale.sol";
import "./MockERC223Token.sol";


contract MockERC223Crowdsale is MockERC20Crowdsale {
  constructor(uint256 _rate) public MockERC20Crowdsale(_rate) {}

  function _createTokenContract() internal returns (MockERC20Token) {
    return new MockERC223Token();
  }
}
