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
    bool public isFinalized;
    uint public weiRaised;

    event Finalized();
    event Invest(address indexed investor, uint amount);
    event WithdrawTokens(address indexed investor, uint amount);

    modifier onlyInvestor() {
        require(investments[msg.sender] != 0, "you are not investor");
        _;
    }

    constructor(
        address _owner,
        address _investmentAddress
    ) public {
        require(_owner != address(0), "owner address should not be null");
        owner = _owner;
        investmentAddress = _investmentAddress;
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
    }

    function finalize() public onlyOwner {
        require(!isFinalized, "pool is already finalized");
        _preValidateFinalization();
        investmentAddress.transfer(weiRaised);
        isFinalized = true;
        emit Finalized();
    }

    function withdrawTokens(ERC20Basic _token) public onlyInvestor {
        address investor = msg.sender;
        uint tokenAmount = _getTokenAmount(_token, investor);
        require(tokenAmount != 0, "contract have no tokens for you");
        _transferTokens(_token, investor, tokenAmount);
    }

    function _getTokenAmount(ERC20Basic _token, address _investor) internal view returns (uint) {
        uint tokenRaised = _token.balanceOf(this).add(tokensWithdrawn);
        uint investedAmount = investments[_investor];
        uint tokenAmount = investedAmount.mul(tokenRaised).div(weiRaised);
        return tokenAmount.sub(tokensWithdrawnByInvestor[_investor]);
    }

    function _transferTokens(ERC20Basic _token, address _investor, uint _amount) internal {
        _token.transfer(_investor, _amount);
        tokensWithdrawnByInvestor[_investor] = tokensWithdrawnByInvestor[_investor].add(_amount);
        tokensWithdrawn = tokensWithdrawn.add(_amount);
        emit WithdrawTokens(_investor, _amount);
    }

    function _preValidateInvest(address _beneficiary, uint) internal {
        require(_beneficiary != address(0), "cannot invest from null address");
        require(investmentAddress != address(0), "investment address did not set");
        require(!isFinalized, "contract is already finalized");
    }

    function _preValidateFinalization() internal {
        // override
    }
}
