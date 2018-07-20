const Crowdsale = artifacts.require('./MockERC20Crowdsale.sol');
const InvestmentPool = artifacts.require('./InvestmentPool.sol');

module.exports = function (deployer, network, accounts) {
    return deployer.deploy(Crowdsale)
        .then(crowdsale => crowdsale.token() // eslint-disable-line promise/no-nesting
            .then(tokenAddress => deployer.deploy(InvestmentPool, accounts[0], crowdsale.address, tokenAddress, 0)));
};
