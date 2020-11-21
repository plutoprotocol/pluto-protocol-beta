const PEther = artifacts.require("PEther");
const PUsdt = artifacts.require("PErc20");
const RiskManager = artifacts.require("RiskManager");

contract("PEther", async accounts => {
    it("should redeemUnderlying properly", async () => {
        let pEtherInstance = await PEther.deployed();
        let pUsdtInstance = await PUsdt.deployed();
        let riskMgrInstance = await RiskManager.deployed();
        let account = accounts[0];

        await riskMgrInstance.enterMarkets([pEtherInstance.address, pUsdtInstance.address]);
        let priceCost = await riskMgrInstance.getPriceCost(account);
        let depositAmount = web3.utils.toWei('0.1', 'ether');
        await pEtherInstance.mint({value: depositAmount})

        let cash = await pEtherInstance.getCash();
        assert.equal(cash, depositAmount);
        let pEtherBalance = await pEtherInstance.balanceOf(account);
        assert.equal(pEtherBalance, web3.utils.toWei('5', 'ether'));

        // first redeem 0.01
        await pEtherInstance.redeemUnderlying(web3.utils.toWei('0.01', 'ether'), {value: priceCost});
        // then redeem all left
        let balanceOfUnderlying = await pEtherInstance.balanceOfUnderlying.call(account);
        await pEtherInstance.redeemUnderlying(balanceOfUnderlying, {value: priceCost});

        cash = await pEtherInstance.getCash();
        assert.equal(cash, 0);
        balanceOfUnderlying = await pEtherInstance.balanceOfUnderlying.call(account);
        assert.equal(balanceOfUnderlying, 0);
    });
})