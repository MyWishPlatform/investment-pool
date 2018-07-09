pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol";


contract TestCrowdsale is Crowdsale {
  constructor(uint256 _rate, address _wallet, ERC20 _token)
    public
    Crowdsale(_rate, _wallet, _token)
  {
  }
}
