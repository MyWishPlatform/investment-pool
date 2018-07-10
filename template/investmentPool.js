const BigNumber = web3.BigNumber;

require('chai')
    .use(require('chai-bignumber')(BigNumber))
    .use(require('chai-as-promised'))
    .should();

const { timeTo, increaseTime, snapshot, revert } = require('sc-library/test-utils/evmMethods');
const { web3async } = require('sc-library/test-utils/web3Utils');
const getBalance = (address) => web3async(web3.eth, web3.eth.getBalance, address);

const InvestmentPool = artifacts.require('./InvestmentPool.sol');
const Crowdsale = artifacts.require('./TestCrowdsale.sol');
const Token = artifacts.require('./TestToken.sol');

const RATE = 1000;
const START_TIME = D_START_TIME; // eslint-disable-line no-undef
const END_TIME = D_END_TIME; // eslint-disable-line no-undef
const SOFT_CAP_WEI = new BigNumber('D_SOFT_CAP_WEI');
const HARD_CAP_WEI = new BigNumber('D_HARD_CAP_WEI');
const MIN_VALUE_WEI = new BigNumber('D_MIN_VALUE_WEI');
const MAX_VALUE_WEI = new BigNumber('D_MAX_VALUE_WEI');
const REWARD_PERMILLE = D_REWARD_PERMILLE; // eslint-disable-line no-undef

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
        return InvestmentPool.new(OWNER, 0, 0);
    };

    const createInvestmentPoolWithICO = async () => {
        const token = await Token.new();
        const crowdsale = await Crowdsale.new(RATE, ICO_WALLET, token.address);
        return InvestmentPool.new(OWNER, crowdsale.address, 0);
    };

    const createInvestmentPoolWithToken = async () => {
        const token = await Token.new();
        return InvestmentPool.new(OWNER, 0, token.address);
    };

    const createInvestmentPoolWithICOAndToken = async () => {
        const token = await Token.new();
        const crowdsale = await Crowdsale.new(RATE, ICO_WALLET, token.address);
        return InvestmentPool.new(OWNER, crowdsale.address, token.address);
    };

    beforeEach(async () => {
        snapshotId = (await snapshot()).result;
        const block = await web3async(web3.eth, web3.eth.getBlock, 'latest');
        now = block.timestamp;
    });

    afterEach(async () => {
        await revert(snapshotId);
    });

    it('#1 construct investment pool', async () => {
        const investmentPool = await createInvestmentPool();
        investmentPool.address.should.have.length(42);
    });

    it('#2 construct investment pool with ICO', async () => {
        const investmentPool = await createInvestmentPoolWithICO();
        investmentPool.address.should.have.length(42);
        const crowdsale = Crowdsale.at(await investmentPool.investmentAddress());
        crowdsale.address.should.have.length(42);
        (await crowdsale.token()).should.have.length(42);
    });

    it('#3 construct investment pool with Token', async () => {
        const investmentPool = await createInvestmentPoolWithToken();
        investmentPool.address.should.have.length(42);
        const token = Token.at(await investmentPool.tokenAddress());
        token.address.should.have.length(42);
    });

    it('#4 construct investment pool with ICO and Token', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        investmentPool.address.should.have.length(42);
        const crowdsale = Crowdsale.at(await investmentPool.investmentAddress());
        crowdsale.address.should.have.length(42);
        const token = Crowdsale.at(await investmentPool.tokenAddress());
        token.address.should.have.length(42);
    });

    it('#5 invest before start and after end', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();

        //#if D_WHITELIST
        await investmentPool.addAddressToWhitelist(INVESTOR_1, { from: OWNER });
        //#endif

        let wei = SOFT_CAP_WEI.div(2).floor();
        //#if D_SOFT_CAP_WEI == 0
        wei = HARD_CAP_WEI.div(2).floor();
        //#endif

        //#if D_MAX_VALUE_WEI != 0 && D_MIN_VALUE_WEI != 0
        wei = BigNumber.max(BigNumber.min(wei, MAX_VALUE_WEI), MIN_VALUE_WEI);
        //#elif D_MAX_VALUE_WEI != 0
        wei = BigNumber.min(wei, MAX_VALUE_WEI);
        //#elif D_MIN_VALUE_WEI != 0
        wei = BigNumber.max(wei, MIN_VALUE_WEI);
        //#endif

        await investmentPool.sendTransaction({ from: INVESTOR_1, value: wei }).should.eventually.be.rejected;
        await timeTo(END_TIME);
        await investmentPool.sendTransaction({ from: INVESTOR_1, value: wei }).should.eventually.be.rejected;
    });

    it('#6 invest in time', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        const crowdsale = Crowdsale.at(await investmentPool.investmentAddress());
        const token = Token.at(await crowdsale.token());

        //#if D_WHITELIST
        await investmentPool.addAddressToWhitelist(INVESTOR_1, { from: OWNER });
        //#endif

        let wei = SOFT_CAP_WEI.div(2).floor();
        //#if D_SOFT_CAP_WEI == 0
        wei = HARD_CAP_WEI.div(2).floor();
        //#endif

        //#if D_MAX_VALUE_WEI != 0 && D_MIN_VALUE_WEI != 0
        wei = BigNumber.max(BigNumber.min(wei, MAX_VALUE_WEI), MIN_VALUE_WEI);
        //#elif D_MAX_VALUE_WEI != 0
        wei = BigNumber.min(wei, MAX_VALUE_WEI);
        //#elif D_MIN_VALUE_WEI != 0
        wei = BigNumber.max(wei, MIN_VALUE_WEI);
        //#endif

        await investmentPool.sendTransaction({ from: INVESTOR_1, value: wei }).should.eventually.be.rejected;
        await timeTo(START_TIME);
        await investmentPool.sendTransaction({ from: INVESTOR_1, value: wei });
        await investmentPool.investments(INVESTOR_1).should.eventually.be.bignumber.equal(wei);
    });

    //#if D_MAX_VALUE_WEI != 0 || D_MIN_VALUE_WEI != 0
    it('#7 check min & max', async () => {
        const investmentPool = await createInvestmentPool();
        await investmentPool;
    });
    //#endif

    it('#8 invest more than hardCap', async () => {
    });

    it('#9 check successfully finalization', async () => {
    });
});
