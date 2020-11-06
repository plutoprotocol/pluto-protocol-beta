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
        await deployer.deploy(NestPriceOracle, MockNest3VoteFactory.address, "0xD287Bc43eCD3D892204aA3792165fe8728636E29");
        await deployer.deploy(RiskManager).then(async function (instance) {
            await instance._setPriceOracle(NestPriceOracle.address);
            oracle = await instance.oracle();
        });
        await deployer.deploy(InterestModel, "20000000000000000", "200000000000000000");
        await deployer.deploy(pETH, RiskManager.address, InterestModel.address, "20000000000000000", "PoolX ETH", "pETH", 18, accounts[0])
        await deployer.deploy(pUSDT, TetherToken.address, RiskManager.address, InterestModel.address, "20000", "PoolX USDT", "pUSDT", 18, accounts[0])

        let riskManagerInstance = await RiskManager.deployed();
        await riskManagerInstance._supportMarket(pETH.address);
        await riskManagerInstance._supportMarket(pUSDT.address);
        let allSupportedMarkets = await riskManagerInstance.getAllMarkets();
        console.log(allSupportedMarkets);
    }

    if (network == "ropsten") {
        let tetherToken = "0xf17D721369F540f7485E1033194eBf92e3f88079";
        await deployer.deploy(MockNest3VoteFactory);
        await deployer.deploy(NestPriceOracle, MockNest3VoteFactory.address, "0xD287Bc43eCD3D892204aA3792165fe8728636E29");
        await deployer.deploy(RiskManager).then(async function (instance) {
            await instance._setPriceOracle(NestPriceOracle.address);
            oracle = await instance.oracle();
        });
        await deployer.deploy(InterestModel, "20000000000000000", "200000000000000000");
        await deployer.deploy(pETH, RiskManager.address, InterestModel.address, "20000000000000000", "Pluto ETH", "pETH", 18, accounts[0])
        await deployer.deploy(pUSDT, tetherToken, RiskManager.address, InterestModel.address, "20000", "Pluto USDT", "pUSDT", 18, accounts[0])

        let riskManagerInstance = await RiskManager.deployed();
        await riskManagerInstance._supportMarket(pETH.address);
        await riskManagerInstance._supportMarket(pUSDT.address);
        await riskManagerInstance._setCollateralFactor(pETH.address, 0.75e18.toString())
        await riskManagerInstance._setCollateralFactor(pUSDT.address, 0.75e18.toString())
        let allSupportedMarkets = await riskManagerInstance.getAllMarkets();
        console.log(allSupportedMarkets);
    }
};
