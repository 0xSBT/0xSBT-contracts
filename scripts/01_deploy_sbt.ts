import { ethers } from "hardhat";

async function main() {
  const SBTContract = await ethers.getContractFactory("BoilerPlateSBT");
  const SBTContractDeployed = await SBTContract.deploy("Test SBT", "TSBT");

  await SBTContractDeployed.deployed();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
