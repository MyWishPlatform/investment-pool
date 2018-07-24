pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";

contract BatchTransferableInvestmentPool is BaseInvestmentPool {

    function generateList() internal returns (address[]) {
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


    function batchPage(uint _index) internal returns (address[]) {
        address[] memory list = generateList();

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


    function transferPage(uint _index) public nonReentrant onlyOwner {
        address[] memory page = batchPage(_index);

        for (uint i = 0; i < page.length; i ++) {
            if (investments[page[i]] != 0) {
              _withdrawInvestorTokens(page[i]);
            }
            if (page[i] == owner && rewardPermille != 0) {
              _withdrawOwnerTokens();
            }
        }
    }
}
