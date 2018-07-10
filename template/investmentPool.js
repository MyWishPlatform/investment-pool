const BigNumber = web3.BigNumber;

require('chai')
    .use(require('chai-bignumber')(BigNumber))
    .use(require('chai-as-promised'))
    .should();

const { increaseTime, snapshot, revert } = require('sc-library/test-utils/evmMethods');
const { web3async } = require('sc-library/test-utils/web3Utils');
const getBalance = (address) => web3async(web3.eth, web3.eth.getBalance, address);

const InvestmentPool = artifacts.require('./InvestmentPool.sol');
const Crowdsale = artifacts.require('./TestCrowdsale.sol');
const Token = artifacts.require('./TestToken.sol');

const RATE = 1000;

const SECOND = 1;
const MINUTE = 60 * SECOND;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

contract('InvestmentPool', function (accounts) {
    const DEPLOYER = accounts[0];
    const OWNER = accounts[1];
    const INVESTOR_1 = accounts[2];
    const INVESTOR_2 = accounts[3];
    const INVESTOR_3 = accounts[4];
    const ICO_WALLET = accounts[5];

    let now;
    let snapshotId;

    const createInvestmentPool = async () => {
        const token = await Token.new();
        const crowdsale = await Crowdsale.new(RATE, ICO_WALLET, token.address);
        return InvestmentPool.new(OWNER, crowdsale.address);
    };

    beforeEach(async () => {
        snapshotId = (await snapshot()).result;
        const block = await web3async(web3.eth, web3.eth.getBlock, 'latest');
        now = block.timestamp;
    });

    afterEach(async () => {
        await revert(snapshotId);
    });

    it('#1 construct', async () => {
        const investmentPool = await createInvestmentPool();
        investmentPool.address.should.have.length(42);
        const crowdsale = Crowdsale.at(await investmentPool.investmentAddress());
        crowdsale.address.should.have.length(42);
        (await crowdsale.token()).should.have.length(42);
    });
});
