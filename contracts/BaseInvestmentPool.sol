pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


contract BaseInvestmentPool is Ownable {
    using SafeMath for uint;

    mapping (address => uint) public investments;
    uint public weiRaised;
    address public investmentAddress;
    bool public isFinalized;

    event Finalized();
    event Invest(address _beneficiary, uint _amount);

    constructor(
        address _owner,
        address _investmentAddress
    ) public {
        require(_owner != address(0), "owner address should not be null");
        owner = _owner;
        investmentAddress = _investmentAddress;
    }

    function () external payable {
        invest(msg.sender);
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
        isFinalized = true;
        emit Finalized();
    }

    function _preValidateInvest(address _beneficiary, uint) internal {
        require(_beneficiary != address(0), "cannot invest from null address");
        require(investmentAddress != address(0), "investment address did not set");
    }
}
