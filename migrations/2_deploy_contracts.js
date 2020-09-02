const MockNest3VoteFactory = artifacts.require("MockNest3VoteFactory");
const TetherToken = artifacts.require("TetherToken");
const InterestModel = artifacts.require("DefaultInterestRateModel");
const RiskManager = artifacts.require("RiskManager");
const NestPriceOracle = artifacts.require("NestPriceOracle");
const pETH = artifacts.require("PEther");
const pUSDT = artifacts.require("PErc20");

module.exports = async function(deployer, network, accounts) {
    if (network == "development") {
        await deployer.deploy(TetherToken, "1000000000000000", "Tether USD", "USDT", 6);
        await deployer.deploy(MockNest3VoteFactory);
        await deployer.deploy(NestPriceOracle, MockNest3VoteFactory.address);
        await deployer.deploy(RiskManager).then(async function (instance) {
            await instance._setPriceOracle(NestPriceOracle.address);
            oracle = await instance.oracle();
        });
        await deployer.deploy(InterestModel, "20000000000000000", "200000000000000000");
        await deployer.deploy(pETH, RiskManager.address, InterestModel.address, "1000000000000000000", "PoolX ETH", "pETH", 18, accounts[0])
        await deployer.deploy(pUSDT, TetherToken.address, RiskManager.address, InterestModel.address, "1000000", "PoolX USDT", "pUSDT", 18, accounts[0])

        let riskManagerInstance = await RiskManager.deployed();
        await riskManagerInstance._supportMarket(pETH.address);
        await riskManagerInstance._supportMarket(pUSDT.address);
        let allSupportedMarkets = await riskManagerInstance.getAllMarkets();
        console.log(allSupportedMarkets);
    }
};
