const MockNestQuery = artifacts.require("MockNestQuery");
const TetherToken = artifacts.require("TetherToken");
const InterestModel = artifacts.require("DefaultInterestRateModel");
const RiskManager = artifacts.require("RiskManager");
const NestPriceOracle = artifacts.require("NestPriceOracle");
const pETH = artifacts.require("PEther");
const pUSDT = artifacts.require("PErc20");
const PlutoLens = artifacts.require("PlutoLens");
const Maximillion = artifacts.require("Maximillion");
const NestQuery = artifacts.require("INestQuery");

module.exports = async function(deployer, network, accounts) {
    console.log(`truffle deploying to ${network} network`);

    let tetherToken = "0xf17D721369F540f7485E1033194eBf92e3f88079";
    let nestQuery = "0xc726A3ae2c9bB2A904b4B62Cf59f5092ba8B6126";
    if (network == "development" || network == "ropsten" || network == "heco") {
        if (network == "development" || network == "heco") {
            await deployer.deploy(TetherToken, "1000000000000000", "Tether USD", "USDT", 6);
            tetherToken = TetherToken.address;
        }
        await deployer.deploy(MockNestQuery);
        nestQuery = MockNestQuery.address;
    }

    if (network == 'mainnet' || network == 'mainnet-fork') {
        tetherToken = "0xdac17f958d2ee523a2206206994597c13d831ec7";
        nestQuery = "0x3bf046c114385357838D9cAE9509C6fBBfE306d2";
    }
    await deployer.deploy(PlutoLens);
    await deployer.deploy(NestPriceOracle, nestQuery);
    let nestQueryInstance = await NestQuery.at(nestQuery);
    await nestQueryInstance.activate(NestPriceOracle.address);

    await deployer.deploy(RiskManager);
    // Interest model with 2% base rate and 20% multiplier
    await deployer.deploy(InterestModel, 0.02e18.toString(), 0.2e18.toString(), 0.9e18.toString(), 5e18.toString());
    // 1 ETH = 50 pETH
    await deployer.deploy(pETH, RiskManager.address, InterestModel.address, 0.02e18.toString(), "PlutoETH", accounts[0])
    // 1 USDT = 50 pUSDT
    await deployer.deploy(pUSDT, tetherToken, RiskManager.address, InterestModel.address, 0.02e6.toString(), "PlutoUSDT", accounts[0])
    await deployer.deploy(Maximillion, pETH.address);

    // ============== Initial Parameters Setting ============
    let riskManagerInstance = await RiskManager.deployed();
    await riskManagerInstance._setPriceOracle(NestPriceOracle.address);
    await riskManagerInstance._supportMarket(pETH.address);
    await riskManagerInstance._supportMarket(pUSDT.address);
    // Activate nest price oracle
    let nestPriceOracleInstance = await NestPriceOracle.deployed();

    let priceCost = await nestPriceOracleInstance.getPriceCost(pETH.address);
    await riskManagerInstance._setCollateralFactor(pETH.address, 0.5e18.toString(), {value: priceCost});

    priceCost = await nestPriceOracleInstance.getPriceCost(pUSDT.address);
    await riskManagerInstance._setCollateralFactor(pUSDT.address, 0.5e18.toString(), {value: priceCost});
    let allSupportedMarkets = await riskManagerInstance.getAllMarkets();
    console.log(allSupportedMarkets);

    console.log(`Contract Deployed Summary\n=========================`);
    console.log(`| USDT | ${tetherToken} |`);
    console.log(`| NestPriceOracle | ${NestPriceOracle.address} |`);
    console.log(`| NestQuery | ${nestQuery} |`);
    console.log(`| RiskManager | ${RiskManager.address} |`);
    console.log(`| InterestModel | ${InterestModel.address} |`);
    console.log(`| pETH | ${pETH.address} |`);
    console.log(`| pUSDT | ${pUSDT.address} |`);
    console.log(`| PlutoLens | ${PlutoLens.address} |`);
    console.log(`| Maximillion | ${Maximillion.address} |`);
};
