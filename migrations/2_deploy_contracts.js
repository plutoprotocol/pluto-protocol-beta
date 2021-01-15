const MockNest3VoteFactory = artifacts.require("MockNest3VoteFactory");
const TetherToken = artifacts.require("TetherToken");
const InterestModel = artifacts.require("DefaultInterestRateModel");
const RiskManager = artifacts.require("RiskManager");
const NestPriceOracle = artifacts.require("NestPriceOracle");
const pETH = artifacts.require("PEther");
const pUSDT = artifacts.require("PErc20");
const PlutoLens = artifacts.require("PlutoLens");

module.exports = async function(deployer, network, accounts) {
    console.log(`truffle deploying to ${network} network`);

    let tetherToken = "0xf17D721369F540f7485E1033194eBf92e3f88079";
    let nestToken = "0xf565422eBd4A8976e1e447a849b8B483C68EFD0C";
    let voteFactory = "0xa43f89dE7f9da44aa4d11106D7b829cf6ac0b561";
    if (network == "development" || network == "ropsten") {
        if (network == "development") {
            await deployer.deploy(TetherToken, "1000000000000000", "Tether USD", "USDT", 6);
            tetherToken = TetherToken.address;
        }
        await deployer.deploy(MockNest3VoteFactory);
        voteFactory = MockNest3VoteFactory.address;
    }

    if (network == 'mainnet' || network == 'mainnet-fork') {
        tetherToken = "0xdac17f958d2ee523a2206206994597c13d831ec7";
        nestToken = "0x04abEdA201850aC0124161F037Efd70c74ddC74C";
        voteFactory = "0x6Cd5698E8854Fb6879d6B1C694223b389B465dea";
    }
    await deployer.deploy(PlutoLens);
    await deployer.deploy(NestPriceOracle, voteFactory, nestToken);
    await deployer.deploy(RiskManager);
    // Interest model with 2% base rate and 20% multiplier
    await deployer.deploy(InterestModel, 0.02e18.toString(), 0.2e18.toString());
    // 1 ETH = 50 pETH
    await deployer.deploy(pETH, RiskManager.address, InterestModel.address, 0.02e18.toString(), accounts[0])
    // 1 USDT = 50 pUSDT
    await deployer.deploy(pUSDT, tetherToken, RiskManager.address, InterestModel.address, 0.02e6.toString(), accounts[0])

    // ============== Initial Parameters Setting ============
    let riskManagerInstance = await RiskManager.deployed();
    await riskManagerInstance._setPriceOracle(NestPriceOracle.address);
    await riskManagerInstance._supportMarket(pETH.address);
    await riskManagerInstance._supportMarket(pUSDT.address);
    // Activate nest price oracle
    let nestPriceOracleInstance = await NestPriceOracle.deployed();
    await nestPriceOracleInstance.activation();

    let priceCost = await nestPriceOracleInstance.getPriceCost(pETH.address);
    await riskManagerInstance._setCollateralFactor(pETH.address, 0.5e18.toString(), {value: priceCost});

    priceCost = await nestPriceOracleInstance.getPriceCost(pUSDT.address);
    await riskManagerInstance._setCollateralFactor(pUSDT.address, 0.5e18.toString(), {value: priceCost});
    let allSupportedMarkets = await riskManagerInstance.getAllMarkets();
    console.log(allSupportedMarkets);

    console.log(`Contract Deployed Summary\n=========================`);
    console.log(`| USDT | ${tetherToken} |`);
    console.log(`| NEST | ${nestToken} |`);
    console.log(`| NEST3VoteFactory | ${voteFactory} |`);
    console.log(`| NestPriceOracle | ${NestPriceOracle.address} |`);
    console.log(`| RiskManager | ${RiskManager.address} |`);
    console.log(`| InterestModel | ${InterestModel.address} |`);
    console.log(`| pETH | ${pETH.address} |`);
    console.log(`| pUSDT | ${pUSDT.address} |`);
    console.log(`| PlutoLens | ${PlutoLens.address} |`);
};
