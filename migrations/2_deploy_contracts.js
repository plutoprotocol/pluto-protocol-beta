const InterestModel = artifacts.require("DefaultInterestRateModel");
const RiskManager = artifacts.require("RiskManager");
const NestPriceOracle = artifacts.require("NestPriceOracle");

module.exports = function(deployer) {
    var baseRatePerYear = "20000000000000000";
    var multiplierPerYear = "700000000000000000";

    var nestV3VoteFactory = "";

    deployer.deploy(InterestModel, baseRatePerYear, multiplierPerYear).then(function () {
        deployer.deploy(RiskManager).then(function () {
            deployer.deploy(NestPriceOracle, nestV3VoteFactory).then(function () {
                RiskManager._setPriceOracle(NestPriceOracle)
            });
        })
    });

};
