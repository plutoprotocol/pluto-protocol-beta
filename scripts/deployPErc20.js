const RiskManager = artifacts.require("RiskManager");
const erc20Token = artifacts.require("ERC20");
const pErc20 = artifacts.require("PErc20");
const NestPriceOracle = artifacts.require("NestPriceOracle");

const argv = require('yargs').argv;

let reserveFactor = 0.15e18.toString();
let underlyingTokenAddr = "0xd3f1be7f74d25f39184d2d0670966e2e837562e3";
let collateralFactor = 0.05e18.toString();
let interestModelAddress = "0x84A2EF7467001d970CE79AD71f2Cf4d553f15403";
module.exports = async function(callback) {
    try {
        console.log(`argv> token=${argv.token}, collateralFactor=${argv.collateralFactor}`);
        underlyingTokenAddr = argv.token
        collateralFactor = argv.collateralFactor

        let erc20 = await erc20Token.at(underlyingTokenAddr);
        let decimals = await erc20.decimals();
        let symbol = await erc20.symbol();
        let pTokenName = "Pluto" + symbol;
        let initialExchange = 0.02 * 10 ** decimals;
        console.log(`TokenDecimals: ${decimals}`)
        console.log(`TokenSymbol: ${symbol}`);
    

        let riskManagerInstance = await RiskManager.at(RiskManager.address);
        let admin = await riskManagerInstance.admin();
        console.log(`admin: ${admin}`)
        console.log(`RiskManager: ${RiskManager.address}`)
        console.log(`interestModelAddress: ${interestModelAddress}`)

        let pTokenInstance = await pErc20.new(underlyingTokenAddr, RiskManager.address, interestModelAddress, initialExchange.toString(), pTokenName, admin);
        await pTokenInstance._setReserveFactor(reserveFactor);

        let nestPriceOracleInstance = await NestPriceOracle.at(NestPriceOracle.address);
        let priceCost = await nestPriceOracleInstance.getPriceCost(pTokenInstance.address);
        console.log(`priceCost: ${priceCost}`)

        await riskManagerInstance._supportMarket(pTokenInstance.address);
        console.log(`Done to support market ${pTokenName}: ${pTokenInstance.address}`);

        await riskManagerInstance._setCollateralFactor(pTokenInstance.address, collateralFactor, {value: priceCost});
        console.log("Done to set collateral factor %s for %s %s", collateralFactor, pTokenName, pTokenInstance.address);

        callback();
    } catch (e) {
        callback(e);
    }
}
