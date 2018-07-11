pragma solidity ^0.4.23;

import "./MockToken.sol";


contract MockCrowdsale {
  using SafeMath for uint;

  MockToken public token;
  uint public baseRate;

  constructor(uint256 _rate) public {
    token = new MockToken();
    baseRate = _rate;
  }

  function () external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) public payable {
    uint weiAmount = msg.value;
    uint tokenAmount = weiAmount.mul(getRate());
    token.mint(_beneficiary, tokenAmount);
  }

  function getTokenAmount(uint _weiAmount) public view returns (uint) {
    return _weiAmount.mul(getRate());
  }

  function getRate() public view returns (uint) {
    return baseRate;
  }
}
