pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


contract BatchTransferableInvestmentPool is BaseInvestmentPool {

  //mapping(address => address) private investors;

  address[] public investors;

  function transferToAddressesFromPage(uint _index) external nonReentrant onlyOwner {
    require(_index * 100 < investors.length);

    uint batchLength = 100;
    if (investors.length - _index * 100 < 100) {
      batchLength = investors.length - _index * 100; 
    }

    uint tokenRaised = ERC20Basic(tokenAddress).balanceOf(this).add(tokensWithdrawn);
    uint tokenAmountMultiplex = tokenRaised.mul(1000 - rewardPermille).div(weiRaised.mul(1000));

    for (uint i = 0; i < batchLength; i ++) {
      address currentInvestor = investors[i + (_index * 100)];
      uint tokenAmount = investments[currentInvestor].mul(tokenAmountMultiplex).sub(tokensWithdrawnByInvestor[currentInvestor]);
      if (investments[currentInvestor] != 0 && tokenAmount != 0) {
        super._transferTokens(currentInvestor, tokenAmount);
        tokensWithdrawnByInvestor[currentInvestor] = tokensWithdrawnByInvestor[currentInvestor].add(tokenAmount);
        emit WithdrawTokens(currentInvestor, tokenAmount);
      } else {
        continue;
      }
      if (currentInvestor == owner && rewardPermille != 0) {
        uint ownerTokenAmount = _getRewardTokenAmount();
        if (isFinalized && (ownerTokenAmount != 0)) {
          super._transferTokens(owner, ownerTokenAmount);
          rewardWithdrawn = rewardWithdrawn.add(ownerTokenAmount);
          emit WithdrawReward(owner, ownerTokenAmount);
        } else {
          continue;
        }
      }
    }
  }

  function _preValidateInvest(address _beneficiary, uint _amount) internal {
    super._preValidateInvest(_beneficiary, _amount);
    investors.push(_beneficiary);
  }
}
