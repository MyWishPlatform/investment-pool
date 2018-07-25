const BigNumber = web3.BigNumber;
BigNumber.config({ EXPONENTIAL_AT: 100 });
const pify = require('pify');
const rand = require('random-seed').create(123);
const Web31 = require('web3');
const web31 = new Web31(web3.currentProvider);

require('chai')
    .use(require('chai-bignumber')(BigNumber))
    .use(require('chai-as-promised'))
    .should();

const { timeTo, increaseTime, snapshot, revert } = require('sc-library/test-utils/evmMethods');
const { estimateConstructGas } = require('sc-library/test-utils/web3Utils');

const InvestmentPool = artifacts.require('./InvestmentPool.sol');
const Crowdsale = artifacts.require('./MockERC20Crowdsale.sol');
const MockVestingERC20Crowdsale = artifacts.require('./MockVestingERC20Crowdsale.sol');
const DelayedCrowdsale = artifacts.require('./DelayedERC20Crowdsale.sol');
const Token = artifacts.require('./ERC20.sol');
const ERC223Token = artifacts.require('./MockERC223Token.sol');
const MockCustomCallsContract = artifacts.require('./MockCustomCallsContract.sol');
const MockRefundableCrowdsale = artifacts.require('./MockRefundableCrowdsale.sol');

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
const GAS_PRICE = web3.toWei(100, 'gwei');

contract('InvestmentPool', function (accounts) {
    const OWNER = accounts[1];
    const INVESTORS = [accounts[2], accounts[3], accounts[4]];

    let now;
    let snapshotId;

    const getRandom = (array) => {
        return array[rand(array.length)];
    };

    const getInvestorTokenAmount = (investedAmount, allInvested, allTokenAmount) => {
        return investedAmount.mul(allTokenAmount).mul(1000 - REWARD_PERMILLE).div(allInvested.mul(1000)).floor();
    };

    const getRewardTokenAmount = (allAmount) => {
        return allAmount.mul(REWARD_PERMILLE).div(1000).floor();
    };

    const createInvestmentPool = async () => {
        return InvestmentPool.new(OWNER, 0, 0, 0);
    };

    const createInvestmentPoolWithICO = async () => {
        const crowdsale = await Crowdsale.new();
        return InvestmentPool.new(OWNER, crowdsale.address, 0, 0);
    };

    const createInvestmentPoolWithToken = async () => {
        const crowdsale = await Crowdsale.new();
        const tokenAddress = await crowdsale.token();
        return InvestmentPool.new(OWNER, 0, tokenAddress, 0);
    };

    const createInvestmentPoolWithICOAndToken = async () => {
        const crowdsale = await Crowdsale.new();
        const tokenAddress = await crowdsale.token();
        return InvestmentPool.new(OWNER, crowdsale.address, tokenAddress, 0);
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

    const reach = async (cap, investmentPool, addresses) => {
        //#if D_WHITELIST
        await investmentPool.addAddressesToWhitelist(addresses, { from: OWNER });
        //#endif

        // reach cap
        let wei = cap;
        //#if defined(D_MAX_VALUE_WEI) && D_MAX_VALUE_WEI != 0
        wei = MAX_VALUE_WEI;

        for (let i = 0; i < cap.div(wei).floor(); i++) {
            await investmentPool.sendTransaction({ from: getRandom(addresses), value: wei });
        }

        const remainWeiToCap = cap.sub(await investmentPool.weiRaised());
        if (remainWeiToCap.comparedTo(0) > 0) {
            //#if defined(D_MIN_VALUE_WEI) && D_MIN_VALUE_WEI != 0
            if (remainWeiToCap.comparedTo(MIN_VALUE_WEI) >= 0) {
                await investmentPool.sendTransaction({ from: getRandom(addresses), value: remainWeiToCap });
            }
            //#else
            await investmentPool.sendTransaction({ from: getRandom(addresses), value: remainWeiToCap });
            //#endif
        }
        //#else
        await investmentPool.sendTransaction({ from: getRandom(addresses), value: wei });
        //#endif
    };

    const encode = web31.eth.abi.encodeFunctionSignature;

    beforeEach(async () => {
        snapshotId = (await snapshot()).result;
        const block = await pify(web3.eth.getBlock)('latest');
        now = block.timestamp;
    });

    afterEach(async () => {
        await revert(snapshotId);
    });

    it('#0 gas limit', async () => {
        const crowdsale = await Crowdsale.new();
        const tokenAddress = await crowdsale.token();
        await estimateConstructGas(InvestmentPool, OWNER, crowdsale.address, tokenAddress, 0)
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
        await reach(HARD_CAP_WEI, investmentPool, [INVESTORS[2]]);
        await investmentPool.finalize({ from: OWNER });
        await token.balanceOf(investmentPool.address).should.eventually.be.bignumber.above(0);
    });
    //#endif
    //#if !defined(D_MAX_VALUE_WEI) || ((defined(D_MAX_VALUE_WEI) && (D_HARD_CAP_WEI/D_MAX_VALUE_WEI) < 1000))

    it('#11 check withdraw tokens after finalize', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        const token = Token.at(await investmentPool.tokenAddress());
        await timeTo(START_TIME);
        await reach(HARD_CAP_WEI, investmentPool, INVESTORS);
        //#if D_CAN_FINALIZE_AFTER_HARD_CAP_ONLY_OWNER
        await investmentPool.finalize({ from: INVESTORS[0] }).should.eventually.be.rejected;
        //#endif
        await investmentPool.finalize({ from: OWNER });

        //withdraw
        const weiRaised = await investmentPool.weiRaised();
        const allTokens = await token.balanceOf(investmentPool.address);

        for (let i = 0; i < INVESTORS.length; i++) {
            const invested = await investmentPool.investments(INVESTORS[i]);
            if (invested.comparedTo(0) > 0) {
                let expectedTokens = getInvestorTokenAmount(invested, weiRaised, allTokens);
                if (INVESTORS[i] === OWNER) {
                    expectedTokens = expectedTokens.add(getRewardTokenAmount(allTokens));
                }
                await investmentPool.withdrawTokens({ from: INVESTORS[i] });
                await investmentPool.withdrawTokens({ from: INVESTORS[i] }).should.eventually.be.rejected;
                await token.balanceOf(INVESTORS[i]).should.eventually.be.bignumber.equal(expectedTokens);
            } else {
                await investmentPool.withdrawTokens({ from: INVESTORS[i] }).should.eventually.be.rejected;
            }
        }
    });
    //#endif

    it('#12 finalize and cancel after endTime before reach softCap', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        await timeTo(END_TIME);
        await investmentPool.finalize({ from: OWNER }).should.eventually.be.rejected;
        await investmentPool.cancel({ from: INVESTORS[0] }).should.eventually.be.rejected;
        await investmentPool.cancel({ from: OWNER });
        await investmentPool.cancel({ from: OWNER }).should.eventually.be.rejected;
        await investmentPool.finalize({ from: OWNER }).should.eventually.be.rejected;
    });
    //#if !defined(D_MAX_VALUE_WEI) || ((defined(D_MAX_VALUE_WEI) && (D_SOFT_CAP_WEI/D_MAX_VALUE_WEI) < 1000))

    it('#13 finalize and cancel after endTime after reach softCap', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        await timeTo(START_TIME);
        //#if defined(D_MIN_VALUE_WEI) && D_MIN_VALUE_WEI > 0
        await reach(SOFT_CAP_WEI.add(MIN_VALUE_WEI), investmentPool, INVESTORS);
        //#else
        await reach(SOFT_CAP_WEI, investmentPool, INVESTORS);
        //#endif
        // finalize after endTime
        await timeTo(END_TIME);
        await investmentPool.finalize({ from: OWNER }).should.eventually.be.rejected;
        await investmentPool.cancel({ from: OWNER });
    });
    //#endif

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
        await pify(web3.eth.getBalance)(investmentPool.address).should.eventually.be.bignumber.equal(wei);
        const balanceBeforeRefund = await pify(web3.eth.getBalance)(INVESTORS[0]);

        const poolBalance = await pify(web3.eth.getBalance)(investmentPool.address);

        const refund = await investmentPool.claimRefund({ from: INVESTORS[0] });
        const gasUsed = new BigNumber(refund.receipt.gasUsed).mul(GAS_PRICE);

        const balanceAfterRefund = (await pify(web3.eth.getBalance)(INVESTORS[0])).add(gasUsed);
        const returnedFunds = balanceAfterRefund.sub(balanceBeforeRefund);

        returnedFunds.should.be.bignumber.equal(poolBalance);
    });

    it('#15 refund after endTime but when not cancelled', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        await timeTo(START_TIME);
        //#if D_WHITELIST
        await investmentPool.addAddressToWhitelist(INVESTORS[0], { from: OWNER });
        //#endif

        // add funds
        const wei = getSimpleWeiAmount();
        await investmentPool.sendTransaction({ from: INVESTORS[0], value: wei });

        // reach endTime
        await timeTo(END_TIME);

        // refund
        await pify(web3.eth.getBalance)(investmentPool.address).should.eventually.be.bignumber.equal(wei);
        const balanceBeforeRefund = await pify(web3.eth.getBalance)(INVESTORS[0]);

        const poolBalance = await pify(web3.eth.getBalance)(investmentPool.address);

        const refund = await investmentPool.claimRefund({ from: INVESTORS[0] });
        const gasUsed = new BigNumber(refund.receipt.gasUsed).mul(GAS_PRICE);

        const balanceAfterRefund = (await pify(web3.eth.getBalance)(INVESTORS[0])).add(gasUsed);
        const returnedFunds = balanceAfterRefund.sub(balanceBeforeRefund);

        returnedFunds.should.be.bignumber.equal(poolBalance);
    });
    //#if !defined(D_MAX_VALUE_WEI) || ((defined(D_MAX_VALUE_WEI) && (D_SOFT_CAP_WEI/D_MAX_VALUE_WEI) < 1000))

    it('#16 refund for several investors', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        await timeTo(START_TIME);
        //#if defined(D_MIN_VALUE_WEI) && D_MIN_VALUE_WEI > 0
        await reach(SOFT_CAP_WEI.add(MIN_VALUE_WEI), investmentPool, INVESTORS);
        //#else
        await reach(SOFT_CAP_WEI, investmentPool, INVESTORS);
        //#endif

        // refunds after time
        await timeTo(END_TIME);

        for (let i = 0; i < INVESTORS.length; i++) {
            const balanceBeforeRefund = await pify(web3.eth.getBalance)(INVESTORS[i]);
            const investedBalance = await investmentPool.investments(INVESTORS[i]);
            if (investedBalance.comparedTo(0) === 0) continue;
            const refund = await investmentPool.claimRefund({ from: INVESTORS[i] });
            const gasUsed = new BigNumber(refund.receipt.gasUsed).mul(GAS_PRICE);
            const balanceAfterRefund = (await pify(web3.eth.getBalance)(INVESTORS[i])).add(gasUsed);
            const returnedFunds = balanceAfterRefund.sub(balanceBeforeRefund);
            returnedFunds.should.be.bignumber.equal(investedBalance);
        }
    });
    //#endif

    //#if D_CAN_CHANGE_TIMES
    it('#17 check set end time', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();

        const NEW_END_TIME = Math.floor(START_TIME + (END_TIME - START_TIME) / 2);

        await investmentPool.setEndTime(NEW_END_TIME, { from: OWNER });
        const newEndTime = await investmentPool.endTime();
        Number(newEndTime).should.be.equals(NEW_END_TIME, 'end time was not changed');

        // set end time by other
        await investmentPool.setEndTime(NEW_END_TIME - 1).should.eventually.be.rejected;
        // set end time less then start
        await investmentPool.setEndTime(START_TIME - 1, { from: OWNER }).should.eventually.be.rejected;

        // move till ended
        await increaseTime(NEW_END_TIME - now + 1);
        const hasEnded = await investmentPool.hasEnded();
        hasEnded.should.be.equals(true, 'hasEnded must be true, time shifted to new end time');
    });

    it('#18 check set end time at wrong time', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();

        const NEW_END_TIME = Math.floor(START_TIME + (END_TIME - START_TIME) / 2);

        // move till started
        await increaseTime(START_TIME - now + 1);

        await investmentPool.setEndTime(NEW_END_TIME, { from: OWNER });
        const newEndTime = await investmentPool.endTime();
        Number(newEndTime).should.be.equals(NEW_END_TIME, 'end time was not changed');

        // move till ended
        await increaseTime(NEW_END_TIME - START_TIME + 1);

        // impossible to change end time, because already ended
        await investmentPool.setEndTime(NEW_END_TIME + 2).should.eventually.be.rejected;
    });

    it('#19 check set wrong end time', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();

        const MIDDLE_TIME = START_TIME + (END_TIME - START_TIME) / 2;

        // move till new end time will be in the past
        await timeTo(MIDDLE_TIME);

        // end time in the past
        await investmentPool.setEndTime(MIDDLE_TIME).should.eventually.be.rejected;
    });

    it('#20 check set start time', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        const NEW_START_TIME = Math.floor(START_TIME + (END_TIME - START_TIME) / 2);

        await investmentPool.setStartTime(NEW_START_TIME, { from: OWNER });
        const newStartTime = await investmentPool.startTime();
        Number(newStartTime).should.be.equals(NEW_START_TIME, 'start time was not changed');

        // set start time by other
        await investmentPool.setStartTime(NEW_START_TIME + 1).should.eventually.be.rejected;
        // set start time grate then end
        await investmentPool.setStartTime(END_TIME + 1, { from: OWNER }).should.eventually.be.rejected;

        // move when already started
        await increaseTime(NEW_START_TIME - now + 1);
        const hasStarted = await investmentPool.hasStarted();
        hasStarted.should.be.equals(true, 'hasStarted must be true, time shifted to new start time');
    });

    it('#21 check set start time at wrong time', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();

        // move till started
        await timeTo(START_TIME + 1);

        const NEW_START_TIME = Math.floor(START_TIME + (END_TIME - START_TIME) / 2);

        await investmentPool.setStartTime(NEW_START_TIME, { from: OWNER }).should.eventually.be.rejected;

        // move till ended
        await timeTo(END_TIME + 1);

        // impossible to change start time, because already ended
        await investmentPool.setStartTime(END_TIME + 10, { from: OWNER }).should.eventually.be.rejected;
    });

    it('#22 check set wrong start time', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        // after the end
        const NEW_START_TIME = END_TIME + 1;

        await investmentPool.setStartTime(NEW_START_TIME, { from: OWNER }).should.eventually.be.rejected;
    });

    it('#23 check set start time/end time', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        // after the end
        const MIDDLE_TIME = Math.floor(START_TIME + (END_TIME - START_TIME) / 2);

        await investmentPool.setTimes(MIDDLE_TIME + 1, MIDDLE_TIME - 1, { from: OWNER }).should.eventually.be.rejected;

        await investmentPool.setTimes(START_TIME - 1, END_TIME, { from: OWNER }).should.eventually.be.rejected;

        await investmentPool.setTimes(MIDDLE_TIME - 1, MIDDLE_TIME + 1, { from: OWNER });
        const newStartTime = await investmentPool.startTime();
        Number(newStartTime).should.be.equals(MIDDLE_TIME - 1, 'start time was not changed');

        const newEndTime = await investmentPool.endTime();
        Number(newEndTime).should.be.equals(MIDDLE_TIME + 1, 'end time was not changed');

        await timeTo(MIDDLE_TIME - 10);
        await investmentPool.setTimes(MIDDLE_TIME, MIDDLE_TIME + 20, { from: OWNER });

        await timeTo(MIDDLE_TIME + 10);
        // already started
        await investmentPool.setTimes(MIDDLE_TIME + 1, END_TIME, { from: OWNER }).should.eventually.be.rejected;
        // end time in the past
        await investmentPool.setTimes(MIDDLE_TIME, MIDDLE_TIME + 5, { from: OWNER }).should.eventually.be.rejected;

        await investmentPool.setTimes(MIDDLE_TIME, MIDDLE_TIME + 30, { from: OWNER });

        const finalEndTime = await investmentPool.endTime();
        Number(finalEndTime).should.be.equals(MIDDLE_TIME + 30, 'end time was not changed');

        await timeTo(MIDDLE_TIME + 31);
        // already ended
        await investmentPool.setTimes(MIDDLE_TIME, END_TIME, { from: OWNER }).should.eventually.be.rejected;
    });
    //#endif

    //#if D_WHITELIST
    it('#24 check buy not by whitelisted', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        await timeTo(START_TIME);
        await investmentPool.sendTransaction({ from: INVESTORS[0], value: getSimpleWeiAmount() })
            .should.eventually.be.rejected;
    });

    it('#25 check add multiple addresses to whitelist', async () => {
        let wei = getSimpleWeiAmount();
        for (let i = 0; i < INVESTORS.length; i++) {
            await revert(snapshotId);
            snapshotId = (await snapshot()).result;

            const investmentPool = await createInvestmentPoolWithICOAndToken();
            await timeTo(START_TIME);

            await investmentPool.addAddressesToWhitelist(INVESTORS, { from: OWNER });
            await investmentPool.sendTransaction({ from: INVESTORS[i], value: wei });
        }
    });

    it('#26 check remove addresses from whitelist', async () => {
        let wei = getSimpleWeiAmount();

        const investmentPool = await createInvestmentPoolWithICOAndToken();
        await timeTo(START_TIME);

        await investmentPool.addAddressesToWhitelist(INVESTORS, { from: OWNER });

        await investmentPool.removeAddressFromWhitelist(INVESTORS[0], { from: OWNER });
        await investmentPool.sendTransaction({ from: INVESTORS[0], value: wei }).should.eventually.be.rejected;

        await investmentPool.removeAddressesFromWhitelist(INVESTORS, { from: OWNER });
        for (let i = 0; i < INVESTORS.length; i++) {
            await investmentPool.sendTransaction({ from: INVESTORS[i], value: wei }).should.eventually.be.rejected;
        }
    });

    it('#27 check whitelist 100 addresses', async () => {
        const addresses = new Array(100).fill(accounts[0]);
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        const tx = await investmentPool.addAddressesToWhitelist(addresses, { from: OWNER });
        console.info('Gas used for whitelist 100 addresses: ', tx.receipt.gasUsed);
    });
    //#endif
    //#if !defined(D_MAX_VALUE_WEI) || ((defined(D_MAX_VALUE_WEI) && (D_SOFT_CAP_WEI/D_MAX_VALUE_WEI) < 1000))

    it('#28 check correct withdrawing when owner participated', async () => {
        const addresses = [...INVESTORS, OWNER];
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        const token = Token.at(await investmentPool.tokenAddress());
        await timeTo(START_TIME);
        //#if defined(D_MIN_VALUE_WEI) && D_MIN_VALUE_WEI > 0
        await reach(SOFT_CAP_WEI.add(MIN_VALUE_WEI), investmentPool, addresses);
        //#else
        await reach(SOFT_CAP_WEI, investmentPool, addresses);
        //#endif

        // finalize
        await investmentPool.finalize({ from: OWNER });

        //withdraw
        const weiRaised = await investmentPool.weiRaised();
        const allTokens = await token.balanceOf(investmentPool.address);

        for (let i = 0; i < addresses.length; i++) {
            const invested = await investmentPool.investments(addresses[i]);
            if (invested.comparedTo(0) > 0) {
                let expectedTokens = getInvestorTokenAmount(invested, weiRaised, allTokens);
                if (addresses[i] === OWNER) {
                    expectedTokens = expectedTokens.add(getRewardTokenAmount(allTokens));
                }

                await investmentPool.withdrawTokens({ from: addresses[i] });
                await token.balanceOf(addresses[i]).should.eventually.be.bignumber.equal(expectedTokens);
            } else {
                if (addresses[i] !== OWNER) {
                    await investmentPool.withdrawTokens({ from: addresses[i] }).should.eventually.be.rejected;
                }
            }
        }
    });
    //#endif

    it('#29 decline unknown ERC223 tokens', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        const token = await ERC223Token.new();
        await token.mint(investmentPool, 100).should.eventually.be.rejected;
    });
    //#if !defined(D_MAX_VALUE_WEI) || ((defined(D_MAX_VALUE_WEI) && (D_HARD_CAP_WEI/D_MAX_VALUE_WEI) < 1000))

    it('#30 check delayed transfer crowdsale', async () => {
        const crowdsale = await DelayedCrowdsale.new();
        const token = Token.at(await crowdsale.token());
        const investmentPool = await InvestmentPool.new(OWNER, crowdsale.address, token.address, 0);
        await timeTo(START_TIME);
        const addresses = [...INVESTORS, OWNER];
        await reach(HARD_CAP_WEI, investmentPool, addresses);

        // finalize
        await investmentPool.finalize({ from: OWNER });
        await token.balanceOf(investmentPool.address).should.eventually.be.bignumber.zero;

        await crowdsale.finalize();

        //withdraw
        const weiRaised = await investmentPool.weiRaised();
        const allTokens = await token.balanceOf(investmentPool.address);
        allTokens.should.be.bignumber.not.equal(0);

        for (let i = 0; i < addresses.length; i++) {
            const invested = await investmentPool.investments(addresses[i]);
            if (invested.comparedTo(0) > 0) {
                let expectedTokens = getInvestorTokenAmount(invested, weiRaised, allTokens);
                if (addresses[i] === OWNER) {
                    expectedTokens = expectedTokens.add(getRewardTokenAmount(allTokens));
                }
                await investmentPool.withdrawTokens({ from: addresses[i] });
                await token.balanceOf(addresses[i]).should.eventually.be.bignumber.equal(expectedTokens);
            } else {
                if (addresses[i] !== OWNER) {
                    await investmentPool.withdrawTokens({ from: addresses[i] }).should.eventually.be.rejected;
                }
            }
        }
    });
    //#endif
    //#if !defined(D_MAX_VALUE_WEI) || ((defined(D_MAX_VALUE_WEI) && (D_HARD_CAP_WEI/D_MAX_VALUE_WEI) < 1000))

    it('#31 check vesting transfer crowdsale', async () => {
        const crowdsale = await MockVestingERC20Crowdsale.new();
        const token = Token.at(await crowdsale.token());
        const investmentPool = await InvestmentPool.new(OWNER, crowdsale.address, token.address, 0);
        await timeTo(START_TIME);
        await reach(HARD_CAP_WEI, investmentPool, INVESTORS);

        // finalize
        await investmentPool.finalize({ from: OWNER });
        await token.balanceOf(investmentPool.address).should.eventually.be.bignumber.zero;

        // withdraw first half
        await crowdsale.releaseFirstHalfTokens();
        const weiRaised = await investmentPool.weiRaised();
        const allTokens1 = await token.balanceOf(investmentPool.address);
        allTokens1.should.be.bignumber.not.equal(0);

        for (let i = 0; i < INVESTORS.length; i++) {
            const invested = await investmentPool.investments(INVESTORS[i]);
            if (invested.comparedTo(0) > 0) {
                const expectedTokens = getInvestorTokenAmount(
                    invested.div(2).floor(), weiRaised.div(2).floor(), allTokens1);
                await investmentPool.withdrawTokens({ from: INVESTORS[i] });
                await token.balanceOf(INVESTORS[i]).should.eventually.be.bignumber.equal(expectedTokens);
            } else {
                await investmentPool.withdrawTokens({ from: INVESTORS[i] }).should.eventually.be.rejected;
            }
        }

        const ownerBalanceBeforeReward1 = await token.balanceOf(OWNER);
        await investmentPool.withdrawTokens({ from: OWNER });
        await token.balanceOf(OWNER).should.eventually.be.bignumber
            .equal(getRewardTokenAmount(allTokens1).add(ownerBalanceBeforeReward1));

        // withdraw second half
        await crowdsale.releaseSecondHalfTokens();
        const allTokens2 = (await token.balanceOf(investmentPool.address)).add(allTokens1);

        for (let i = 0; i < INVESTORS.length; i++) {
            const invested = await investmentPool.investments(INVESTORS[i]);
            if (invested.comparedTo(0) > 0) {
                const expectedTokens = getInvestorTokenAmount(invested, weiRaised, allTokens2);
                await investmentPool.withdrawTokens({ from: INVESTORS[i] });
                await token.balanceOf(INVESTORS[i]).should.eventually.be.bignumber.equal(expectedTokens);
            } else {
                await investmentPool.withdrawTokens({ from: INVESTORS[i] }).should.eventually.be.rejected;
            }
        }

        await investmentPool.withdrawTokens({ from: OWNER });
        await token.balanceOf(OWNER).should.eventually.be.bignumber.equal(getRewardTokenAmount(allTokens2));
    });
    //#endif

    it('#32 custom call before finalized', async () => {
        const investmentPool = await createInvestmentPool();
        const mockContract = await MockCustomCallsContract.new();
        await investmentPool.setInvestmentAddress(mockContract.address, { from: OWNER });
        await investmentPool.executeAfterFinalize(encode('nonPayableCall()'), { from: OWNER })
            .should.eventually.be.rejected;
    });
    //#if !defined(D_MAX_VALUE_WEI) || ((defined(D_MAX_VALUE_WEI) &(D_SOFT_CAP_WEI/D_MAX_VALUE_WEI) < 1000))

    it('#33 custom call on crowdsale contract', async () => {
        const investmentPool = await createInvestmentPoolWithToken();
        await timeTo(START_TIME);
        const mockContract = await MockCustomCallsContract.new();
        await investmentPool.setInvestmentAddress(mockContract.address, { from: OWNER });
        //#if defined(D_MIN_VALUE_WEI)
        await reach(SOFT_CAP_WEI.add(MIN_VALUE_WEI), investmentPool, [INVESTORS[1]]);
        //#else
        await reach(SOFT_CAP_WEI, investmentPool, [INVESTORS[1]]);
        //#endif
        await investmentPool.finalize({ from: OWNER });
        await investmentPool.executeAfterFinalize(encode('nonPayableCall()'), { from: OWNER });
        await mockContract.isCalledNonPayable().should.eventually.be.true;
    });
    //#endif
    //#if !defined(D_MAX_VALUE_WEI) || ((defined(D_MAX_VALUE_WEI) && (D_SOFT_CAP_WEI/D_MAX_VALUE_WEI) < 1000))

    it('#34 custom payable call on crowdsale contract', async () => {
        const investmentPool = await createInvestmentPoolWithToken();
        await timeTo(START_TIME);
        const mockContract = await MockCustomCallsContract.new();
        await investmentPool.setInvestmentAddress(mockContract.address, { from: OWNER });
        //#if defined(D_MIN_VALUE_WEI)
        await reach(SOFT_CAP_WEI.add(MIN_VALUE_WEI), investmentPool, [INVESTORS[1]]);
        //#else
        await reach(SOFT_CAP_WEI, investmentPool, [INVESTORS[1]]);
        //#endif
        await investmentPool.finalize({ from: OWNER });
        await investmentPool.executeAfterFinalize(encode('payableCall()'), { from: OWNER, value: 100 });
        await mockContract.isCalledPayable().should.eventually.be.true;
    });
    //#endif
    //#if !defined(D_MAX_VALUE_WEI) || ((defined(D_MAX_VALUE_WEI) && (D_SOFT_CAP_WEI/D_MAX_VALUE_WEI) < 1000))

    it('#35 custom requiring funds call on crowdsale contract', async () => {
        const investmentPool = await createInvestmentPoolWithToken();
        await timeTo(START_TIME);
        const mockContract = await MockCustomCallsContract.new();
        await investmentPool.setInvestmentAddress(mockContract.address, { from: OWNER });
        //#if defined(D_MIN_VALUE_WEI)
        await reach(SOFT_CAP_WEI.add(MIN_VALUE_WEI), investmentPool, [INVESTORS[1]]);
        //#else
        await reach(SOFT_CAP_WEI, investmentPool, [INVESTORS[1]]);
        //#endif
        await investmentPool.finalize({ from: OWNER });
        await investmentPool.executeAfterFinalize(encode('payableCallRequiresFunds()'), { from: OWNER });
        await mockContract.isCalledPayableRequiredFunds().should.eventually.be.false;
        await investmentPool.executeAfterFinalize(
            encode('payableCallRequiresFunds()'), { from: OWNER, value: 100 });
        await mockContract.isCalledPayableRequiredFunds().should.eventually.be.true;
    });
    //#endif
    //#if !defined(D_MAX_VALUE_WEI) || ((defined(D_MAX_VALUE_WEI) && (D_SOFT_CAP_WEI/D_MAX_VALUE_WEI) < 1000))

    it('#36 custom returning funds call on crowdsale contract', async () => {
        const investmentPool = await createInvestmentPoolWithToken();
        await timeTo(START_TIME);
        const mockContract = await MockCustomCallsContract.new();
        await investmentPool.setInvestmentAddress(mockContract.address, { from: OWNER });
        //#if D_SOFT_CAP_WEI == 0
        await reach(new BigNumber(100), investmentPool, [INVESTORS[1]]);
        //#else
        //#if defined(D_MIN_VALUE_WEI)
        await reach(SOFT_CAP_WEI.add(MIN_VALUE_WEI), investmentPool, [INVESTORS[1]]);
        //#else
        await reach(SOFT_CAP_WEI, investmentPool, [INVESTORS[1]]);
        //#endif
        //#endif
        const reachedBalance = await pify(web3.eth.getBalance)(investmentPool.address);
        await investmentPool.finalize({ from: OWNER });
        await investmentPool.executeAfterFinalize(encode('returningFundsCall()'), { from: OWNER });
        await mockContract.isCalledReturningFunds().should.eventually.be.true;
        await pify(web3.eth.getBalance)(investmentPool.address).should.eventually.be.bignumber.equal(reachedBalance);
    });
    //#endif
    //#if !defined(D_MAX_VALUE_WEI) || ((defined(D_MAX_VALUE_WEI) && (D_HARD_CAP_WEI/D_MAX_VALUE_WEI) < 1000))

    it('#37 refund after ICO refunded', async () => {
        const investmentPool = await createInvestmentPoolWithToken();
        const mockContract = await MockCustomCallsContract.new();
        await investmentPool.setInvestmentAddress(mockContract.address, { from: OWNER });
        await timeTo(START_TIME);
        //#if D_WHITELIST
        await investmentPool.addAddressToWhitelist(INVESTORS[0], { from: OWNER });
        //#endif

        // add funds
        await reach(HARD_CAP_WEI, investmentPool, [INVESTORS[0]]);

        // finalize
        await investmentPool.finalize({ from: OWNER });

        // ico refund
        await investmentPool.executeAfterFinalize(encode('returningFundsCall()'), { from: OWNER });

        // IPool refund
        await investmentPool.hardCapReached().should.eventually.be.equal(true);
        const balanceBeforeRefund = await pify(web3.eth.getBalance)(INVESTORS[0]);
        const expectedRefund = await investmentPool.investments(INVESTORS[0]);
        const refund = await investmentPool.claimRefund({ from: INVESTORS[0] });
        const gasUsed = new BigNumber(refund.receipt.gasUsed).mul(GAS_PRICE);
        const balanceAfterRefund = (await pify(web3.eth.getBalance)(INVESTORS[0])).add(gasUsed);
        const returnedFunds = balanceAfterRefund.sub(balanceBeforeRefund);
        returnedFunds.should.be.bignumber.equal(expectedRefund);
    });
    //#endif
    //#if !defined(D_MAX_VALUE_WEI) || ((defined(D_MAX_VALUE_WEI) && (D_HARD_CAP_WEI/D_MAX_VALUE_WEI) < 1000))

    it('#38 refund from another address', async () => {
        const investmentPool = await createInvestmentPoolWithToken();
        const mockContract = await MockRefundableCrowdsale.new();
        await investmentPool.setInvestmentAddress(mockContract.address, { from: OWNER });
        await timeTo(START_TIME);
        //#if D_WHITELIST
        await investmentPool.addAddressToWhitelist(INVESTORS[0], { from: OWNER });
        //#endif

        // add funds
        await reach(HARD_CAP_WEI, investmentPool, [INVESTORS[0]]);
        const reachedBalance = await pify(web3.eth.getBalance)(investmentPool.address);

        // finalize
        await investmentPool.finalize({ from: OWNER });
        const vaultAddress = await mockContract.vault();
        await pify(web3.eth.getBalance)(vaultAddress).should.eventually.be.bignumber.equal(reachedBalance);

        // ico refund
        await investmentPool.executeAfterFinalize(encode('refund()'), { from: OWNER });

        // IPool refund
        await pify(web3.eth.getBalance)(vaultAddress).should.eventually.be.bignumber.equal(0);
        await pify(web3.eth.getBalance)(investmentPool.address).should.eventually.be.bignumber.equal(reachedBalance);
        const balanceBeforeRefund = await pify(web3.eth.getBalance)(INVESTORS[0]);
        const expectedRefund = await investmentPool.investments(INVESTORS[0]);
        const refund = await investmentPool.claimRefund({ from: INVESTORS[0] });
        const gasUsed = new BigNumber(refund.receipt.gasUsed).mul(GAS_PRICE);
        const balanceAfterRefund = (await pify(web3.eth.getBalance)(INVESTORS[0])).add(gasUsed);
        const returnedFunds = balanceAfterRefund.sub(balanceBeforeRefund);
        returnedFunds.should.be.bignumber.equal(expectedRefund);
    });
    //#endif
    //#if !defined(D_MAX_VALUE_WEI) || ((defined(D_MAX_VALUE_WEI) && (D_SOFT_CAP_WEI/D_MAX_VALUE_WEI) < 1000))

    it('#39 service account may execute', async () => {
        const serviceAccount = INVESTORS[0];
        const mockContract = await MockCustomCallsContract.new();
        const crowdsale = await Crowdsale.new();
        const tokenAddress = await crowdsale.token();
        const investmentPool = await InvestmentPool.new(OWNER, mockContract.address, tokenAddress, serviceAccount);
        await timeTo(START_TIME);
        //#if D_SOFT_CAP_WEI == 0
        await reach(new BigNumber(100), investmentPool, [INVESTORS[1]]);
        //#else
        //#if defined(D_MIN_VALUE_WEI)
        await reach(SOFT_CAP_WEI.add(MIN_VALUE_WEI), investmentPool, [INVESTORS[1]]);
        //#else
        await reach(SOFT_CAP_WEI, investmentPool, [INVESTORS[1]]);
        //#endif
        //#endif
        await investmentPool.finalize({ from: OWNER });
        await investmentPool.executeAfterFinalize(encode('nonPayableCall()'), { from: INVESTORS[1] })
            .should.eventually.be.rejected;
        await investmentPool.executeAfterFinalize(encode('nonPayableCall()'), { from: serviceAccount });
        await mockContract.isCalledNonPayable().should.eventually.be.true;
    });
    //#endif
    //#if !defined(D_MAX_VALUE_WEI) || ((defined(D_MAX_VALUE_WEI) && (D_SOFT_CAP_WEI/D_MAX_VALUE_WEI) < 1000))

    it('#40 who can send funds after soft cap', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        await timeTo(START_TIME);
        //#if defined(D_MIN_VALUE_WEI)
        await reach(SOFT_CAP_WEI.add(MIN_VALUE_WEI), investmentPool, [INVESTORS[1]]);
        //#else
        await reach(SOFT_CAP_WEI, investmentPool, [INVESTORS[1]]);
        //#endif
        //#if D_CAN_FINALIZE_AFTER_SOFT_CAP_ONLY_OWNER
        await investmentPool.finalize({ from: INVESTORS[0] }).should.eventually.be.rejected;
        await investmentPool.finalize({ from: OWNER });
        //#else
        await investmentPool.finalize({ from: INVESTORS[0] });
        //#endif
    });
    //#endif
    //#if !defined(D_MAX_VALUE_WEI) || ((defined(D_MAX_VALUE_WEI) && (D_HARD_CAP_WEI/D_MAX_VALUE_WEI) < 1000))

    it('#41 who can send funds after hard cap', async () => {
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        await timeTo(START_TIME);
        await reach(HARD_CAP_WEI, investmentPool, INVESTORS);
        //#if D_CAN_FINALIZE_AFTER_HARD_CAP_ONLY_OWNER
        await investmentPool.finalize({ from: INVESTORS[0] }).should.eventually.be.rejected;
        await investmentPool.finalize({ from: OWNER });
        //#else
        await investmentPool.finalize({ from: INVESTORS[0] });
        //#endif
    });
    //#endif

    it('#43 check transfer from page', async () => {
        const addresses = Array.from({ length: 102 }, (v, k) => accounts[k + 1]);

        let wei = getSimpleWeiAmount();
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        await timeTo(START_TIME);

        await investmentPool.addAddressesToWhitelist(addresses, { from: OWNER });
        for (let i = 0; i < addresses.length; i++) {
            await investmentPool.sendTransaction({ from: addresses[i], value: wei });
        }

        await investmentPool.finalize({ from: OWNER });
        const tx = await investmentPool.batchTransferFromPage(0, { from: OWNER }).should.be.fulfilled;
        console.info('Gas used for transfer to 100 addresses: ', tx.receipt.gasUsed);
    });

    it('#44 if page have less than 100 addresses', async () => {
        const addresses = Array.from({ length: 102 }, (v, k) => accounts[k++]);

        let wei = getSimpleWeiAmount();
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        await timeTo(START_TIME);

        await investmentPool.addAddressesToWhitelist(addresses, { from: OWNER });
        for (let i = 0; i < addresses.length; i++) {
            await investmentPool.sendTransaction({ from: addresses[i], value: wei });
        }

        await investmentPool.finalize({ from: OWNER });
        await investmentPool.batchTransferFromPage(1, { from: OWNER }).should.be.fulfilled;
    });

    it('#45 check correct amount transferred to addresses from page', async () => {
        const addresses = Array.from({ length: 10 }, (v, k) => accounts[k++]);
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        const token = Token.at(await investmentPool.tokenAddress());
        await timeTo(START_TIME);
        //#if defined(D_MIN_VALUE_WEI) && D_MIN_VALUE_WEI > 0
        await reach(SOFT_CAP_WEI.add(MIN_VALUE_WEI), investmentPool, addresses);
        //#else
        await reach(SOFT_CAP_WEI, investmentPool, addresses);
        //#endif

        let wei = getSimpleWeiAmount();
        for (let i = 0; i < addresses.length; i++) {
            await investmentPool.sendTransaction({ from: addresses[i], value: wei });
        }
        // finalize
        await investmentPool.finalize({ from: OWNER });

        //withdraw
        const weiRaised = await investmentPool.weiRaised();
        const allTokens = await token.balanceOf(investmentPool.address);

        await investmentPool.batchTransferFromPage(0, { from: OWNER }).should.be.fulfilled;

        for (let i = 0; i < addresses.length; i++) {
            const invested = await investmentPool.investments(addresses[i]);
            if (invested.comparedTo(0) > 0) {
                let expectedTokens = getInvestorTokenAmount(invested, weiRaised, allTokens);

                await token.balanceOf(addresses[i]).should.eventually.be.bignumber.equal(expectedTokens);
                if (addresses[i] !== OWNER) {
                    await investmentPool.withdrawTokens({ from: addresses[i] }).should.eventually.be.rejected;
                }
            }
        }
    });


    it('#46 check transfer from non-existed page', async () => {
        const addresses = Array.from({ length: 20 }, (v, k) => accounts[k++]);
        let wei = getSimpleWeiAmount();
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        await timeTo(START_TIME);

        await investmentPool.addAddressesToWhitelist(addresses, { from: OWNER });
        for (let i = 0; i < addresses.length; i++) {
            await investmentPool.sendTransaction({ from: addresses[i], value: wei });
        }
        await investmentPool.finalize({ from: OWNER });
        await investmentPool.batchTransferFromPage(1, { from: OWNER }).should.be.rejected;
    });

    it('#47 if address from page already withdrawed', async () => {
        const addresses = Array.from({ length: 20 }, (v, k) => accounts[k + 1]);
        let wei = getSimpleWeiAmount();
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        const token = Token.at(await investmentPool.tokenAddress());
        await timeTo(START_TIME);

        await investmentPool.addAddressesToWhitelist(addresses, { from: OWNER });
        for (let i = 0; i < addresses.length; i++) {
            await investmentPool.sendTransaction({ from: addresses[i], value: wei });
        }
        await investmentPool.finalize({ from: OWNER });
        await investmentPool.withdrawTokens({ from: accounts[6] });
        const beforeListTransfer = await token.balanceOf(accounts[6]);
        await investmentPool.batchTransferFromPage(0, { from: OWNER });
        await token.balanceOf(accounts[6]).should.eventually.be.bignumber.equal(beforeListTransfer);
    });

    it('#48 if owner already withdrawed and claimed reward', async () => {
        const addresses = Array.from({ length: 5 }, (v, k) => accounts[k++]);
        let wei = getSimpleWeiAmount();
        const investmentPool = await createInvestmentPoolWithICOAndToken();
        const token = Token.at(await investmentPool.tokenAddress());
        await timeTo(START_TIME);

        await investmentPool.addAddressesToWhitelist(addresses, { from: OWNER });
        for (let i = 0; i < addresses.length; i++) {
            await investmentPool.sendTransaction({ from: addresses[i], value: wei });
        }

        await investmentPool.finalize({ from: OWNER });
        await investmentPool.withdrawTokens({ from: OWNER });
        const beforeListTransfer = await token.balanceOf(OWNER);
        await investmentPool.batchTransferFromPage(0, { from: OWNER });

        await token.balanceOf(OWNER).should.eventually.be.bignumber.equal(beforeListTransfer);
        await investmentPool.withdrawTokens({ from: OWNER }).should.eventually.be.rejected;
    });
});
