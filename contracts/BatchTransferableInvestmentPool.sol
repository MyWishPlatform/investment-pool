pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


contract BatchTransferableInvestmentPool is BaseInvestmentPool {

  uint constant BATCH_SIZE = 100;
  address[] public investors;

  function batchTransferFromPage(uint _index) external nonReentrant {
    uint indexOffset = _index * BATCH_SIZE;
    require(indexOffset < investors.length);

    uint batchLength = BATCH_SIZE;
    if (investors.length - indexOffset < BATCH_SIZE) {
      batchLength = investors.length - indexOffset;
    }

    uint tokenRaised = ERC20Basic(tokenAddress).balanceOf(this).add(tokensWithdrawn);
    uint tokenAmountMultiplex = tokenRaised.mul(1000 - rewardPermille).div(weiRaised.mul(1000));

    uint batchTokenAmount;
    for (uint i = 0; i < batchLength; i ++) {
      address currentInvestor = investors[i + (indexOffset)];
      uint invested = investments[currentInvestor];
      uint tokenAmount = invested.mul(tokenAmountMultiplex).sub(tokensWithdrawnByInvestor[currentInvestor]);

      if (invested == 0 || tokenAmount == 0) {
        continue;
      } else {
        ERC20Basic(tokenAddress).transfer(currentInvestor, tokenAmount);
        batchTokenAmount += tokenAmount;

        tokensWithdrawnByInvestor[currentInvestor] += tokenAmount;
        emit WithdrawTokens(currentInvestor, tokenAmount);
      }
    }
    tokensWithdrawn += batchTokenAmount;
  }

  function _preValidateInvest(address _beneficiary, uint _amount) internal {
    super._preValidateInvest(_beneficiary, _amount);
    if (investments[_beneficiary] == 0) {
      investors.push(_beneficiary);
    }
  }
}
