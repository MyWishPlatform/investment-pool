pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol";
import "sc-library/contracts/ERC223/ERC223Receiver.sol";


contract BaseInvestmentPool is Ownable, ERC223Receiver {
  using SafeMath for uint;

  mapping(address => uint) public tokensWithdrawnByInvestor;
  mapping(address => uint) public investments;
  address public investmentAddress;
  uint public tokensWithdrawn;
  uint public rewardWithdrawn;
  uint public rewardPermille;
  uint public weiRaised;
  bool public isFinalized;

  event Finalized();
  event Invest(address indexed investor, uint amount);
  event WithdrawTokens(address indexed investor, uint amount);
  event WithdrawReward(uint amount);
  event SetInvestmentAddress(address investmentAddress);

  modifier onlyInvestor() {
    require(investments[msg.sender] != 0, "you are not investor");
    _;
  }

  constructor(
    address _owner,
    address _investmentAddress,
    uint _rewardPermille
  )
    public
  {
    require(_owner != address(0), "owner address should not be null");
    require(_rewardPermille < 1000, "rate should be less than 1000");
    owner = _owner;
    investmentAddress = _investmentAddress;
    rewardPermille = _rewardPermille;
  }

  function() external payable {
    invest(msg.sender);
  }

  function tokenFallback(address, uint, bytes) public {
    // apply tokens from ICO
  }

  function invest(address _beneficiary) public payable {
    uint amount = msg.value;
    _preValidateInvest(_beneficiary, amount);
    weiRaised = weiRaised.add(amount);
    investments[_beneficiary] = investments[_beneficiary].add(amount);
    emit Invest(_beneficiary, amount);
  }

  function setInvestmentAddress(address _investmentAddress) public onlyOwner {
    require(investmentAddress == address(0), "investment address already set");
    investmentAddress = _investmentAddress;
    emit SetInvestmentAddress(_investmentAddress);
  }

  function finalize() public {
    require(!isFinalized, "pool is already finalized");
    _preValidateFinalization();
    investmentAddress.transfer(weiRaised);
    isFinalized = true;
    emit Finalized();
  }

  function forwardReward(ERC20Basic _token) public onlyOwner {
    require(isFinalized, "contract not finalized yet");
    uint tokenAmount = _getRewardTokenAmount(_token);
    require(tokenAmount != 0, "contract have no tokens for you");
    _transferTokens(_token, owner, tokenAmount);
    emit WithdrawReward(tokenAmount);
  }

  function withdrawTokens(ERC20Basic _token) public onlyInvestor {
    address investor = msg.sender;
    uint tokenAmount = _getInvestorTokenAmount(_token, investor);
    require(tokenAmount != 0, "contract have no tokens for you");
    _transferTokens(_token, investor, tokenAmount);
    tokensWithdrawnByInvestor[investor] = tokensWithdrawnByInvestor[investor].add(tokenAmount);
    emit WithdrawTokens(investor, tokenAmount);
  }

  function _getRewardTokenAmount(ERC20Basic _token) internal view returns (uint) {
    uint tokenRaised = _token.balanceOf(this).add(tokensWithdrawn);
    uint tokenAmount = tokenRaised * rewardPermille / 1000;
    return tokenAmount.sub(rewardWithdrawn);
  }

  function _getInvestorTokenAmount(ERC20Basic _token, address _investor) internal view returns (uint) {
    uint tokenRaised = _token.balanceOf(this).add(tokensWithdrawn);
    uint investorsTokens = tokenRaised.mul(1000 - rewardPermille).div(1000);
    uint investedAmount = investments[_investor];
    uint tokenAmount = investedAmount.mul(investorsTokens).div(weiRaised);
    return tokenAmount.sub(tokensWithdrawnByInvestor[_investor]);
  }

  function _transferTokens(ERC20Basic _token, address _investor, uint _amount) internal {
    _token.transfer(_investor, _amount);
    tokensWithdrawn = tokensWithdrawn.add(_amount);
  }

  function _preValidateInvest(address _beneficiary, uint) internal {
    require(_beneficiary != address(0), "cannot invest from null address");
    require(investmentAddress != address(0), "investment address did not set");
    require(!isFinalized, "contract is already finalized");
  }

  function _preValidateFinalization() internal {
    require(investmentAddress != address(0), "investment address did not set");
  }
}
