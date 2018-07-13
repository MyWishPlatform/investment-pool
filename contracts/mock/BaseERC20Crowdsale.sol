pragma solidity ^0.4.23;

import "./MockERC20Token.sol";


contract BaseERC20Crowdsale {
  using SafeMath for uint;

  mapping(address => uint) public tokens;
  address[] public investors;
  MockERC20Token public token;

  constructor() public {
    token = _createTokenContract();
  }

  function () external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) public payable {
    uint weiAmount = msg.value;
    if (!_alreadyInvested(_beneficiary)) {
      investors.push(_beneficiary);
    }
    uint tokenAmount = weiAmount.mul(getRate());
    tokens[_beneficiary] = tokens[_beneficiary].add(tokenAmount);
  }

  function getRate() public pure returns (uint) {
    return 1000;
  }

  function _forwardTokens(address _to, uint _amount) internal {
    if (_amount != 0) {
      token.mint(_to, _amount);
      tokens[_to] = 0;
    }
  }

  function _createTokenContract() internal returns (MockERC20Token) {
    return new MockERC20Token();
  }

  function _alreadyInvested(address _investor) internal view returns (bool) {
    for (uint i = 0; i < investors.length; i++) {
      if (investors[i] == _investor) {
        return true;
      }
    }
    return false;
  }
}
