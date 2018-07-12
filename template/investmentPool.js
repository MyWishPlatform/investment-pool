const BigNumber = web3.BigNumber;
const rand = require('random-seed').create(123);
require('chai')
    .use(require('chai-bignumber')(BigNumber))
    .use(require('chai-as-promised'))
    .should();

const { timeTo, increaseTime, snapshot, revert } = require('sc-library/test-utils/evmMethods');
const { web3async, estimateConstructGas } = require('sc-library/test-utils/web3Utils');
const getBalance = (address) => web3async(web3.eth, web3.eth.getBalance, address);

const InvestmentPool = artifacts.require('./InvestmentPool.sol');
const Crowdsale = artifacts.require('./MockCrowdsale.sol');
const Token = artifacts.require('./ERC20.sol');

const RATE = 1000;
const START_TIME = D_START_TIME; // eslint-disable-line no-undef
const END_TIME = D_END_TIME; // eslint-disable-line no-undef
const SOFT_CAP_WEI = new BigNumber('D_SOFT_CAP_WEI');
const HARD_CAP_WEI = new BigNumber('D_HARD_CAP_WEI');
//#ifdef D_MIN_VALUE_WEI
const MIN_VALUE_WEI = new BigNumber('D_MIN_VALUE_WEI');
//#endif
//#ifdef D_MAX_VALUE_WEI
const MAX_VALUE_WEI = new BigNumber('D_MAX_VALUE_WEI');
//#endif
const REWARD_PERMILLE = D_REWARD_PERMILLE; // eslint-disable-line no-undef

const SECOND = 1;
const MINUTE = 60 * SECOND;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;
const GAS_PRICE = web3.toWei(100, 'gwei');

contract('InvestmentPool', function (accounts) {
    const DEPLOYER = accounts[0];
    const OWNER = accounts[1];
    const INVESTORS = [accounts[2], accounts[3], accounts[4]];

    let now;
    let snapshotId;

    const getRandomInvestor = () => {
        return INVESTORS[rand(INVESTORS.length)];
    };

    const getInvestorTokenAmount = (investedAmount, allInvested, allTokenAmount) => {
        return investedAmount.div(allInvested).mul(allTokenAmount.sub(getRewardTokenAmount(allTokenAmount))).floor();
    };

    const getRewardTokenAmount = (allAmount) => {
        return allAmount.mul(REWARD_PERMILLE).div(1000).floor();
    };

    const createInvestmentPool = async () => {
        return InvestmentPool.new(OWNER, 0, 0);
    };

    const createInvestmentPoolWithICO = async () => {
        const crowdsale = await Crowdsale.new(RATE);
        return InvestmentPool.new(OWNER, crowdsale.address, 0);
    };

    const createInvestmentPoolWithToken = async () => {
        const crowdsale = await Crowdsale.new(RATE);
        const tokenAddress = await crowdsale.token();
        return InvestmentPool.new(OWNER, 0, tokenAddress);
    };

    const createInvestmentPoolWithICOAndToken = async () => {
        const crowdsale = await Crowdsale.new(RATE);
        const tokenAddress = await crowdsale.token();
        return InvestmentPool.new(OWNER, crowdsale.address, tokenAddress);
    };

    const getSimpleWeiAmount = () => {
        let wei = SOFT_CAP_WEI.div(2).floor();
        //#if D_SOFT_CAP_WEI == 0
        wei = HARD_CAP_WEI.div(2).floor();
        //#endif
        //#if defined(D_MAX_VALUE_WEI) && defined(D_MIN_VALUE_WEI) && D_MAX_VALUE_WEI != 0 && D_MIN_VALUE_WEI != 0
        wei = BigNumber.max(BigNumber.min(wei, MAX_VALUE_WEI), MIN_VALUE_WEI);
        //#elif defined(D_MAX_VALUE_WEI) && D_MAX_VALUE_WEI != 0
        wei = BigNumber.min(wei, MAX_VALUE_WEI);
        //#elif defined(D_MIN_VALUE_WEI) && D_MIN_VALUE_WEI != 0
        wei = BigNumber.max(wei, MIN_VALUE_WEI);
        //#endif
        return wei;
    };

    beforeEach(async () => {
        snapshotId = (await snapshot()).result;
        const block = await web3async(web3.eth, web3.eth.getBlock, 'latest');
        now = block.timestamp;
    });

    afterEach(async () => {
        await revert(snapshotId);
    });

    it('#0 gas limit', async () => {
        const crowdsale = await Crowdsale.new(RATE);
        const tokenAddress = await crowdsale.token();
        await estimateConstructGas(InvestmentPool, OWNER, crowdsale.address, tokenAddress)
            .then(gas => console.info('Construct gas:', gas));
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
        await investmentPool.addAddressToWhitelist(INVESTORS[0], { from: OWNER });
        //#endif

        const wei = getSimpleWeiAmount();
        await investmentPool.sendTransaction({ from: INVESTORS[0], value: wei }).should.eventually.be.rejected;
        await timeTo(END_TIME);
        await investmentPool.sendTransaction({ from: INVESTORS[0], value: wei }).should.eventually.be.rejected;
    });

    it('#6 invest in time', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();

        //#if D_WHITELIST
        await investmentPool.addAddressToWhitelist(INVESTORS[0], { from: OWNER });
        //#endif

        const wei = getSimpleWeiAmount();
        await investmentPool.sendTransaction({ from: INVESTORS[0], value: wei }).should.eventually.be.rejected;
        await timeTo(START_TIME);
        await investmentPool.sendTransaction({ from: INVESTORS[0], value: wei });
        await investmentPool.investments(INVESTORS[0]).should.eventually.be.bignumber.equal(wei);
    });
    //#if defined(D_MAX_VALUE_WEI) && D_MAX_VALUE_WEI != 0 || defined(D_MIN_VALUE_WEI) && D_MIN_VALUE_WEI != 0

    it('#7 check min & max', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        await timeTo(START_TIME);
        //#if D_WHITELIST
        await investmentPool.addAddressToWhitelist(INVESTORS[0], { from: OWNER });
        //#endif
        //#if defined(D_MIN_VALUE_WEI) && D_MIN_VALUE_WEI != 0
        await investmentPool.sendTransaction({ from: INVESTORS[0], value: MIN_VALUE_WEI.sub(1) })
            .should.eventually.be.rejected;
        //#endif
        //#if defined(D_MAX_VALUE_WEI) && D_MAX_VALUE_WEI != 0
        await investmentPool.sendTransaction({ from: INVESTORS[0], value: MAX_VALUE_WEI.add(1) })
            .should.eventually.be.rejected;
        //#endif
    });
    //#endif
    //#if defined(D_MAX_VALUE_WEI) && (D_MAX_VALUE_WEI > D_HARD_CAP_WEI)

    it('#9 cannot invest more than hardCap', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        await timeTo(START_TIME);
        //#if D_WHITELIST
        await investmentPool.addAddressToWhitelist(INVESTORS[0], { from: OWNER });
        //#endif
        await investmentPool.sendTransaction({ from: INVESTORS[0], value: HARD_CAP_WEI.add(web3.toWei(1, 'ether')) })
            .should.eventually.be.rejected;
    });
    //#endif
    //#if !defined(D_MAX_VALUE_WEI) || ((defined(D_MAX_VALUE_WEI) && (D_HARD_CAP_WEI/D_MAX_VALUE_WEI) < 1000))

    it('#10 check successfully finalization', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        const token = Token.at(await investmentPool.tokenAddress());
        await timeTo(START_TIME);
        //#if D_WHITELIST
        await investmentPool.addAddressToWhitelist(INVESTORS[2], { from: OWNER });
        //#endif

        // reach hard cap
        let wei = HARD_CAP_WEI;
        //#if defined(D_MAX_VALUE_WEI) && D_MAX_VALUE_WEI != 0
        wei = MAX_VALUE_WEI;

        for (let i = 0; i < HARD_CAP_WEI.div(wei).floor(); i++) {
            await investmentPool.sendTransaction({ from: INVESTORS[2], value: wei });
        }

        const remainWeiToHardCap = HARD_CAP_WEI.sub(await investmentPool.weiRaised());
        if (remainWeiToHardCap.comparedTo(0) > 0) {
            //#if defined(D_MIN_VALUE_WEI) && D_MIN_VALUE_WEI != 0
            if (remainWeiToHardCap.comparedTo(MIN_VALUE_WEI) >= 0) {
                await investmentPool.sendTransaction({ from: INVESTORS[2], value: remainWeiToHardCap });
            }
            //#else
            await investmentPool.sendTransaction({ from: INVESTORS[2], value: remainWeiToHardCap });
            //#endif
        }
        //#else
        await investmentPool.sendTransaction({ from: INVESTORS[2], value: wei });
        //#endif

        // finalize
        await investmentPool.finalize({ from: OWNER });
        await token.balanceOf(investmentPool.address).should.eventually.be.bignumber.not.negative;
    });
    //#endif
    //#if !defined(D_MAX_VALUE_WEI) || ((defined(D_MAX_VALUE_WEI) && (D_HARD_CAP_WEI/D_MAX_VALUE_WEI) < 1000))

    it('#11 check withdraw tokens after finalize', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        const token = Token.at(await investmentPool.tokenAddress());
        await timeTo(START_TIME);
        //#if D_WHITELIST
        for (let i = 0; i < INVESTORS.length; i++) {
            await investmentPool.addAddressToWhitelist(INVESTORS[i], { from: OWNER });
        }
        //#endif

        // reach hard cap
        let wei = HARD_CAP_WEI;
        //#if defined(D_MAX_VALUE_WEI) && D_MAX_VALUE_WEI != 0
        wei = MAX_VALUE_WEI;

        for (let i = 0; i < HARD_CAP_WEI.div(wei).floor(); i++) {
            await investmentPool.sendTransaction({ from: getRandomInvestor(), value: wei });
        }

        const remainWeiToHardCap = HARD_CAP_WEI.sub(await investmentPool.weiRaised());
        if (remainWeiToHardCap.comparedTo(0) > 0) {
            //#if defined(D_MIN_VALUE_WEI) && D_MIN_VALUE_WEI != 0
            if (remainWeiToHardCap.comparedTo(MIN_VALUE_WEI) >= 0) {
                await investmentPool.sendTransaction({ from: getRandomInvestor(), value: remainWeiToHardCap });
            }
            //#else
            await investmentPool.sendTransaction({ from: getRandomInvestor(), value: remainWeiToHardCap });
            //#endif
        }
        //#else
        await investmentPool.sendTransaction({ from: getRandomInvestor(), value: wei });
        //#endif

        // finalize
        await investmentPool.finalize({ from: OWNER });

        //withdraw

        const weiRaised = await investmentPool.weiRaised();
        const allTokens = await token.balanceOf(investmentPool.address);

        for (let i = 0; i < INVESTORS.length; i++) {
            const invested = await investmentPool.investments(INVESTORS[i]);
            if (invested.comparedTo(0) > 0) {
                const expectedTokens = getInvestorTokenAmount(invested, weiRaised, allTokens);
                await investmentPool.withdrawTokens({ from: INVESTORS[i] });
                await token.balanceOf(INVESTORS[i]).should.eventually.be.bignumber.equal(expectedTokens);
            } else {
                await investmentPool.withdrawTokens({ from: INVESTORS[i] }).should.eventually.be.rejected;
            }
        }

        await investmentPool.forwardReward({ from: OWNER });
        await token.balanceOf(OWNER).should.eventually.be.bignumber.equal(getRewardTokenAmount(allTokens));
    });
    //#endif

    it('#12 finalize and cancel after endTime before reach softCap', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        await timeTo(END_TIME);
        await investmentPool.finalize({ from: OWNER }).should.eventually.be.rejected;
        await investmentPool.cancel({ from: OWNER });
    });

    it('#13 finalize and cancel after endTime after reach softCap', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        await timeTo(START_TIME);
        //#if D_WHITELIST
        for (let i = 0; i < INVESTORS.length; i++) {
            await investmentPool.addAddressToWhitelist(INVESTORS[i], { from: OWNER });
        }
        //#endif

        // reach soft cap
        let wei = SOFT_CAP_WEI;
        //#if defined(D_MAX_VALUE_WEI) && D_MAX_VALUE_WEI != 0
        wei = MAX_VALUE_WEI;

        for (let i = 0; i < SOFT_CAP_WEI.div(wei).floor(); i++) {
            await investmentPool.sendTransaction({ from: getRandomInvestor(), value: wei });
        }

        const remainWeiToSoftCap = SOFT_CAP_WEI.sub(await investmentPool.weiRaised());
        if (remainWeiToSoftCap.comparedTo(0) > 0) {
            //#if defined(D_MIN_VALUE_WEI) && D_MIN_VALUE_WEI != 0
            if (remainWeiToSoftCap.comparedTo(MIN_VALUE_WEI) >= 0) {
                await investmentPool.sendTransaction({ from: getRandomInvestor(), value: remainWeiToSoftCap });
            }
            //#else
            await investmentPool.sendTransaction({ from: getRandomInvestor(), value: remainWeiToSoftCap });
            //#endif
        }
        //#else
        await investmentPool.sendTransaction({ from: getRandomInvestor(), value: wei });
        //#endif

        // finalize after endTime
        await timeTo(END_TIME);
        await investmentPool.finalize({ from: OWNER }).should.eventually.be.rejected;
        await investmentPool.cancel({ from: OWNER });
    });

    it('#14 refund after cancel', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        await timeTo(START_TIME);
        //#if D_WHITELIST
        await investmentPool.addAddressToWhitelist(INVESTORS[0], { from: OWNER });
        //#endif

        // add funds
        const wei = getSimpleWeiAmount();
        await investmentPool.sendTransaction({ from: INVESTORS[0], value: wei });

        // cancel
        await investmentPool.cancel({ from: OWNER });

        // refund
        await getBalance(investmentPool.address).should.eventually.be.bignumber.equal(wei);
        const balanceBeforeRefund = await getBalance(INVESTORS[0]);

        const poolBalance = await getBalance(investmentPool.address);

        const refund = await investmentPool.claimRefund({ from: INVESTORS[0] });
        const gasUsed = new BigNumber(refund.receipt.gasUsed).mul(GAS_PRICE);

        const balanceAfterRefund = (await getBalance(INVESTORS[0])).add(gasUsed);
        const returnedFunds = balanceAfterRefund.sub(balanceBeforeRefund);

        returnedFunds.should.be.bignumber.equal(poolBalance);
    });
});
