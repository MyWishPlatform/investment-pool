pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";

contract BatchTransferableInvestmentPool is BaseInvestmentPool {

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


    function _batchPage(uint _index) internal returns (address[]) {
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


    function _transferInvestorPage(address _investor, uint _amountMultiplex) public {
        uint investedAmount = investments[_investor];
        uint tokenAmount = investments[_investor].mul(_amountMultiplex).sub(tokensWithdrawnByInvestor[_investor]);

        require(tokenAmount != 0, "contract have no tokens for you");
        _transferTokens(_investor, tokenAmount);
        tokensWithdrawnByInvestor[_investor] = tokensWithdrawnByInvestor[_investor].add(tokenAmount);
        emit WithdrawTokens(_investor, tokenAmount);
    }


    function transferPage(uint _index) public nonReentrant onlyOwner {
        address[] memory page = _batchPage(_index);
        uint tokenRaised = ERC20Basic(tokenAddress).balanceOf(this).add(tokensWithdrawn);
        uint tokenAmountMultiplex = tokenRaised.mul(1000 - rewardPermille).div(weiRaised.mul(1000));


        for (uint i = 0; i < page.length; i ++) {
            if (investments[page[i]] != 0) {
                _transferInvestorPage(page[i], tokenAmountMultiplex);
            }
            if (page[i] == owner && rewardPermille != 0) {
              _withdrawOwnerTokens();
            }
        }
    }
}
