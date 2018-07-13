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

  /**
   * @param _owner              who will own the InvestmentPool contract.
   * @param _investmentAddress  address to which the funds will be sent after successful collection on the contract.
   * @param _tokenAddress       the address of the contract token whose token we want to receive.
   * @param _rewardPermille     owner of contract will receive (_rewardPermille / 1000 * all tokens collected) as a fee.
   */
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

  /**
   * @notice fallback function applying funds.
   */
  function() external payable {
    invest(msg.sender);
  }

  /**
   * @notice sends all funds to investmentAddress.
   */
  function finalize() external nonReentrant {
    require(!isFinalized, "pool is already finalized");
    _preValidateFinalization();
    // solium-disable-next-line security/no-call-value
    require(investmentAddress.call.value(weiRaised)(), "error when sending funds to ICO");
    isFinalized = true;
    emit Finalized();
  }

  /**
   * @notice withdraws sender's tokens.
   */
  function withdrawTokens() external nonReentrant {
    require(msg.sender == owner || investments[msg.sender] != 0, "you are not owner and not investor");
    if (investments[msg.sender] != 0) {
      _withdrawInvestorTokens(msg.sender);
    }
    if (msg.sender == owner) {
      _withdrawOwnerTokens();
    }
  }

  /**
   * @notice token receiver fallback function for compatibility with ERC223. Applies ERC223 tokens from ICO.
   */
  function tokenFallback(address, uint, bytes) public {
    require(msg.sender == tokenAddress, "allowed receive tokens only from target ICO");
  }

  /**
   * @notice apply funds from investor.
   *
   * @param _beneficiary investor.
   */
  function invest(address _beneficiary) public payable {
    uint amount = msg.value;
    _preValidateInvest(_beneficiary, amount);
    weiRaised = weiRaised.add(amount);
    investments[_beneficiary] = investments[_beneficiary].add(amount);
    emit Invest(_beneficiary, amount);
  }

  /**
   * @notice sets investments address if it was not set early.
   *
   * @param _investmentAddress investment address to set.
   */
  function setInvestmentAddress(address _investmentAddress) public onlyOwner {
    require(investmentAddress == address(0), "investment address already set");
    investmentAddress = _investmentAddress;
    emit SetInvestmentAddress(_investmentAddress);
  }

  /**
   * @notice sets token address if it was not set early.
   *
   * @param _tokenAddress token address to set.
   */
  function setTokenAddress(address _tokenAddress) public onlyOwner {
    require(tokenAddress == address(0), "token address already set");
    tokenAddress = _tokenAddress;
    emit SetTokenAddress(_tokenAddress);
  }

  /**
   * @notice withdraws investors's part of tokens.
   */
  function _withdrawInvestorTokens(address _investor) internal {
    uint tokenAmount = _getInvestorTokenAmount(_investor);
    require(tokenAmount != 0, "contract have no tokens for you");
    _transferTokens(_investor, tokenAmount);
    tokensWithdrawnByInvestor[_investor] = tokensWithdrawnByInvestor[_investor].add(tokenAmount);
    emit WithdrawTokens(_investor, tokenAmount);
  }

  /**
   * @notice withdraws owner's percent of tokens.
   */
  function _withdrawOwnerTokens() internal {
    require(isFinalized, "contract not finalized yet");
    uint tokenAmount = _getRewardTokenAmount();
    require(tokenAmount != 0, "contract have no tokens for you");
    _transferTokens(owner, tokenAmount);
    rewardWithdrawn = rewardWithdrawn.add(tokenAmount);
    emit WithdrawReward(owner, tokenAmount);
  }

  /**
   * @return how much tokens will owner receive.
   */
  function _getRewardTokenAmount() internal view returns (uint) {
    uint tokenRaised = ERC20Basic(tokenAddress).balanceOf(this).add(tokensWithdrawn);
    uint tokenAmount = tokenRaised.mul(rewardPermille).div(1000);
    return tokenAmount.sub(rewardWithdrawn);
  }

  /**
   * @param _investor investor address.
   * @return how much tokens will investor receive.
   */
  function _getInvestorTokenAmount(address _investor) internal view returns (uint) {
    uint tokenRaised = ERC20Basic(tokenAddress).balanceOf(this).add(tokensWithdrawn);
    uint investedAmount = investments[_investor];
    uint tokenAmount = investedAmount.mul(tokenRaised).mul(1000 - rewardPermille).div(weiRaised.mul(1000));
    return tokenAmount.sub(tokensWithdrawnByInvestor[_investor]);
  }

  /**
   * @notice transfers tokens to investor.
   *
   * @param _investor investor address.
   * @param _amount   token amount to transfer.
   */
  function _transferTokens(address _investor, uint _amount) internal {
    ERC20Basic(tokenAddress).transfer(_investor, _amount);
    tokensWithdrawn = tokensWithdrawn.add(_amount);
  }

  /**
   * @notice validates transaction before applying funds from investor.
   *
   * @param _beneficiary  investor address.
   * @param _amount       wei amount investor send.
   */
  function _preValidateInvest(address _beneficiary, uint _amount) internal {
    require(_beneficiary != address(0), "cannot invest from null address");
    require(!isFinalized, "contract is already finalized");
  }

  /**
   * @notice validates transaction before sending funds to ICO.
   */
  function _preValidateFinalization() internal {
    require(investmentAddress != address(0), "investment address did not set");
    require(tokenAddress != address(0), "token address did not set");
  }
}
