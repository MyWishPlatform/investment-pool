const InvestmentPool = artifacts.require('./InvestmentPool.sol');

module.exports = function (deployer, accounts) {
    deployer.deploy(
        InvestmentPool,
        accounts[0],
        1530896296,
        1530996296,
        10000000000000000,
        20000000000000000,
        accounts[1]
    );
};
