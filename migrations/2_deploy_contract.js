const Token = artifacts.require('./TestToken.sol');
const Crowdsale = artifacts.require('./TestCrowdsale.sol');
const InvestmentPool = artifacts.require('./InvestmentPool.sol');

module.exports = function (deployer, network, accounts) {
    return deployer.deploy(Token)
        .then(token => deployer.deploy(Crowdsale, 1000, accounts[1], token.address)
            .then(crowdsale => deployer.deploy(InvestmentPool, accounts[0], crowdsale.address, token.address)));
};
