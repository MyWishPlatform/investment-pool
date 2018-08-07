pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


/**
 * @title BatchTransferableInvestmentPool
 * @dev The contract extends BaseInvestmentPool and adds possibility of sending tokens to investors.
 */
contract BatchTransferableInvestmentPool is BaseInvestmentPool {
  /**
   * @notice number of investors per one transfer transaction.
   */
  uint public constant BATCH_SIZE = 50;

  /**
   * @notice investors which contributed funds and can get tokens.
   */
  address[] internal investors;

  /**
   * @notice transfers tokens to multiple investors address.
   *
   * @param _index number of page of addresses
   */
  function batchTransferFromPage(uint _index) external nonReentrant {
    uint indexOffset = getOffset(_index);
    uint batchLength = getPageSize(indexOffset);

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

  /**
   * @notice returns number of page, which have unsended investor tokens
   */
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
   * @notice returns total number of investors, who sended money on contract
   */
  function investorsCount() public view returns (uint) {
    return investors.length;
  }

  /**
   * @notice returns rest amount of unreceived tokens on page
   * @param _index number of page
   */
  function pageTokenAmount(uint _index) public view returns (uint batchTokenAmount) {
    uint indexOffset = getOffset(_index);
    uint batchLength = getPageSize(indexOffset);

    for (uint i = 0; i < batchLength; i ++) {
      address currentInvestor = investors[i + (indexOffset)];
      uint tokenAmount = _getInvestorTokenAmount(currentInvestor);

      if (tokenAmount == 0) {
        continue;
      } else {
        batchTokenAmount += tokenAmount;
      }
    }
  }

  /**
   * @notice returns number of investors that have not received tokens yet
   * @param _index number of
   */
  function pageInvestorsRemain(uint _index) public view returns (uint investorsRemain) {
    uint indexOffset = getOffset(_index);
    uint batchLength = getPageSize(indexOffset);

    for (uint i = 0; i < batchLength; i ++) {
      address currentInvestor = investors[i + (indexOffset)];
      uint tokenAmount = _getInvestorTokenAmount(currentInvestor);

      if (tokenAmount == 0) {
        continue;
      } else {
        investorsRemain++;
      }
    }
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

  /**
   * @notice returns correct amount of investors if last page filled partially
   * @param _indexOffset converted page number
   */
  function getPageSize(uint _indexOffset) internal returns (uint batchLength) {
    if (investors.length - _indexOffset < BATCH_SIZE) {
      return investors.length - _indexOffset;
    } else {
      return BATCH_SIZE;
    }
  }

  /**
   * @notice converts index to offset and validates it
   * @param _index number of page
   */
  function getOffset(uint _index) internal returns (uint indexOffset) {
    indexOffset = _index * BATCH_SIZE;
    require(indexOffset < investors.length);
  }
}
