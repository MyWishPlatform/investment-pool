pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol";
import "sc-library/contracts/ERC223/ERC223Receiver.sol";


contract BaseInvestmentPool is Ownable, ReentrancyGuard, ERC223Receiver {
  using SafeMath for uint;

  mapping(address => uint) public tokensWithdrawnByInvestor;
  mapping(address => uint) public investments;
  address public investmentAddress;
  address public tokenAddress;
  uint public tokensWithdrawn;
  uint public rewardWithdrawn;
  uint public rewardPermille;
  uint public weiRaised;
  bool public isFinalized;

  event Finalized();
  event Invest(address indexed investor, uint amount);
  event WithdrawTokens(address indexed investor, uint amount);
  event WithdrawReward(address indexed owner, uint amount);
  event SetInvestmentAddress(address indexed investmentAddress);
  event SetTokenAddress(address indexed tokenAddress);

  modifier onlyInvestor() {
    require(investments[msg.sender] != 0, "you are not investor");
    _;
  }

  constructor(
    address _owner,
    address _investmentAddress,
    address _tokenAddress,
    uint _rewardPermille
  )
    public
  {
    require(_owner != address(0), "owner address should not be null");
    require(_rewardPermille < 1000, "rate should be less than 1000");
    owner = _owner;
    investmentAddress = _investmentAddress;
    tokenAddress = _tokenAddress;
    rewardPermille = _rewardPermille;
  }

  function() external payable {
    invest(msg.sender);
  }

  function finalize() external nonReentrant {
    require(!isFinalized, "pool is already finalized");
    _preValidateFinalization();
    // solium-disable-next-line security/no-call-value
    require(investmentAddress.call.value(weiRaised)(), "error when sending funds to ICO");
    isFinalized = true;
    emit Finalized();
  }

  function forwardReward() external onlyOwner nonReentrant {
    require(isFinalized, "contract not finalized yet");
    uint tokenAmount = _getRewardTokenAmount();
    require(tokenAmount != 0, "contract have no tokens for you");
    _transferTokens(owner, tokenAmount);
    emit WithdrawReward(owner, tokenAmount);
  }

  function withdrawTokens() external onlyInvestor nonReentrant {
    address investor = msg.sender;
    uint tokenAmount = _getInvestorTokenAmount(investor);
    require(tokenAmount != 0, "contract have no tokens for you");
    _transferTokens(investor, tokenAmount);
    tokensWithdrawnByInvestor[investor] = tokensWithdrawnByInvestor[investor].add(tokenAmount);
    emit WithdrawTokens(investor, tokenAmount);
  }

  function tokenFallback(address, uint, bytes) public {
    require(msg.sender == tokenAddress, "allowed receive tokens only from target ICO");
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

  function setTokenAddress(address _tokenAddress) public onlyOwner {
    require(tokenAddress == address(0), "token address already set");
    tokenAddress = _tokenAddress;
    emit SetTokenAddress(_tokenAddress);
  }

  function _getRewardTokenAmount() internal view returns (uint) {
    uint tokenRaised = ERC20Basic(tokenAddress).balanceOf(this).add(tokensWithdrawn);
    uint tokenAmount = tokenRaised * rewardPermille / 1000;
    return tokenAmount.sub(rewardWithdrawn);
  }

  function _getInvestorTokenAmount(address _investor) internal view returns (uint) {
    uint tokenRaised = ERC20Basic(tokenAddress).balanceOf(this).add(tokensWithdrawn);
    uint investedAmount = investments[_investor];
    uint tokenAmount = investedAmount.mul(tokenRaised).mul(1000 - rewardPermille).div(weiRaised.mul(1000));
    return tokenAmount.sub(tokensWithdrawnByInvestor[_investor]);
  }

  function _transferTokens( address _investor, uint _amount) internal {
    ERC20Basic(tokenAddress).transfer(_investor, _amount);
    tokensWithdrawn = tokensWithdrawn.add(_amount);
  }

  function _preValidateInvest(address _beneficiary, uint) internal {
    require(_beneficiary != address(0), "cannot invest from null address");
    require(!isFinalized, "contract is already finalized");
  }

  function _preValidateFinalization() internal {
    require(investmentAddress != address(0), "investment address did not set");
    require(tokenAddress != address(0), "token address did not set");
  }
}
