pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";

contract BatchTransferableInvestmentPool is BaseInvestmentPool {

    function generateList() public view returns (address[]) {
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


    function batchList(uint _index) public view returns (address[]) {
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

}
