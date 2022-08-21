const Migrations = artifacts.require("Migrations");
const MemeToken = artifacts.require("MemeToken");

module.exports = function(deployer) {
    deployer.deploy(Migrations);
    deployer.deploy(MemeToken);
};