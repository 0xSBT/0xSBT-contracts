const Migrations = artifacts.require("Migrations");
const Treasury = artifacts.require("Treasury");
const ksp = "0xd2e72adcdd82e687158541fe196d53ed60caac09";
module.exports = function(deployer) {
    deployer.deploy(Migrations);
    deployer.deploy(Treasury, ksp, ksp, ksp, "0x42271971dbF42fbfEaF7F428604a86760300cB5B", "0x2be2C91cCA2df52b41a9e42723c46fD029359c95");
};