const Migrations = artifacts.require("Migrations");
const Voting = artifacts.require("Voting");
const ksp = "0xd2e72adcdd82e687158541fe196d53ed60caac09";
module.exports = function(deployer) {
    deployer.deploy(Migrations);
    deployer.deploy(Voting, ksp);
};