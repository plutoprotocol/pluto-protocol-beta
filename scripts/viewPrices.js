const RiskManager = artifacts.require("RiskManager");
const NestPriceOracle = artifacts.require("NestPriceOracle");

module.exports = async function(callback) {
    try {
        let riskManagerInstance = await RiskManager.deployed();
        let priceOracle = await NestPriceOracle.deployed();
        let allSupportedMarkets = await riskManagerInstance.getAllMarkets();
        for (market of allSupportedMarkets) {
            let price = await priceOracle.getUnderlyingPrice(market)
            console.log(priceOracle.address)
            console.log(`${market} price: ${price[0].toString()} ${price[1].toString()} `);
        }
        callback();
    } catch (e) {
        console.log(e);
        callback(e);
    }
}