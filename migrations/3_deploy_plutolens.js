const PlutoLens = artifacts.require("PlutoLens");

module.exports = function(deployer) {
    deployer.deploy(PlutoLens);
};