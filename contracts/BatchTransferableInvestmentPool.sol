pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


/**
 * @title BatchTransferableInvestmentPool
 * @dev The contract extends BaseInvestmentPool and adds possibility of sending tokens to investorsю
 */
contract BatchTransferableInvestmentPool is BaseInvestmentPool {
  /**
   * @notice number of investors per one transfer transaction.
   */
  uint constant BATCH_SIZE = 50;

  /**
   * @notice investors which contributed funds and can get tokens.
   */
  address[] internal investors;

  /**
   * @notice transfers tokens to multiple investors address.
   *
   * @param _index number of batch of addresses
   */
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

  function getPage() public view returns (uint) {
      uint firstIndex;
      for (uint i = 0; i < investors.length; i++) {
          uint investorAmount = _getInvestorTokenAmount(investors[i]);
          if (investorAmount != 0) {
              firstIndex = i;
              break;
          }
      }
      return firstIndex.div(BATCH_SIZE);
  }

  /**
   * @notice validates investor's transactions and storing investor's address before adding investor funds
   */
  function _preValidateInvest(address _beneficiary, uint _amount) internal {
    super._preValidateInvest(_beneficiary, _amount);
    if (investments[_beneficiary] == 0) {
      investors.push(_beneficiary);
    }
  }
}
