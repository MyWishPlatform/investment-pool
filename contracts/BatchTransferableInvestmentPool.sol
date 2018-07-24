pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


contract BatchTransferableInvestmentPool is BaseInvestmentPool {

  mapping(address => address) private investors;

  uint internal investorsCount;

  function transferToAddressesFromPage(uint _index) external nonReentrant onlyOwner {
    address[] memory page = _extractPage(_index);
    uint tokenRaised = ERC20Basic(tokenAddress).balanceOf(this).add(tokensWithdrawn);
    uint tokenAmountMultiplex = tokenRaised.mul(1000 - rewardPermille).div(weiRaised.mul(1000));

    for (uint i = 0; i < page.length; i ++) {
      address currentInvestor = page[i];
      if (investments[currentInvestor] != 0) {
        uint tokenAmount = investments[currentInvestor].mul(tokenAmountMultiplex).sub(tokensWithdrawnByInvestor[currentInvestor]);

        require(tokenAmount != 0, "contract have no tokens for you");
        _transferTokens(currentInvestor, tokenAmount);
        tokensWithdrawnByInvestor[currentInvestor] = tokensWithdrawnByInvestor[currentInvestor].add(tokenAmount);
        emit WithdrawTokens(currentInvestor, tokenAmount);
      }
      if (currentInvestor == owner && rewardPermille != 0) {
        _withdrawOwnerTokens();
      }
    }
  }

  function _appendInvestor(address _addr) internal {
    investors[_addr] = investors[0x0];
    investors[0x0] = _addr;
    investorsCount++;
  }

  function _preValidateInvest(address _beneficiary, uint _amount) internal {
    super._preValidateInvest(_beneficiary, _amount);
    _appendInvestor(_beneficiary);
  }

  function _generateList() internal returns (address[]) {
    address[] memory investorsList = new address[](investorsCount);
    address current = investors[0x0];

    for (uint i = 0; i < investorsCount; i ++) {
      investorsList[i] = current;
      current = investors[current];
      if (current == 0x0) {
        break;
      }
    }
    return investorsList;
  }

  function _extractPage(uint _index) internal returns (address[]) {
    require(_index * 100 < investorsCount);
    address[] memory list = _generateList();

    uint batchLength = 100;
    if (investorsCount - _index * 100 < 100) {
      batchLength = investorsCount - _index * 100; 
    }

    address[] memory currentBatch = new address[](batchLength);
    for (uint i = 0; i < batchLength; i ++) {
      currentBatch[i] = list[i + (_index * 100)];
    }

    return currentBatch;
  }
}
