const Crowdsale = artifacts.require('./MockERC20Crowdsale.sol');
const InvestmentPool = artifacts.require('./InvestmentPool.sol');

module.exports = function (deployer, network, accounts) {
    return deployer.deploy(Crowdsale, 1000)
        .then(crowdsale => crowdsale.token()
            .then(tokenAddress => deployer.deploy(InvestmentPool, accounts[0], crowdsale.address, tokenAddress)));
};
