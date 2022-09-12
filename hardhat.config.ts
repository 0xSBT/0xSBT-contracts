import "hardhat-deploy";
import "hardhat-contract-sizer";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-truffle5";
import "@nomiclabs/hardhat-web3";
import "@nomiclabs/hardhat-etherscan";
import "@openzeppelin/hardhat-upgrades";

const accounts = {
  mnemonic: process.env.MNEMONIC || "test test test test test test test test test test test junk",
};

module.exports = {
  defaultNetwork: process.env.NETWORK ? process.env.NETWORK : "localhost",
  networks: {
    localhost: {
      live: false,
      chainId: 31337,
      saveDeployments: true,
      tags: ["local"],
    },
    hardhat: {
      allowUnlimitedContractSize: true,
      live: false,
      chainId: 31337,
      saveDeployments: true,
      tags: ["test", "local"],
      gasPrice: 250000000000,
      accounts: {
        // 1,000,000,000
        accountsBalance: "10000000000000000000000000000",
      },
      // Solidity-coverage overrides gasPrice to 1 which is not compatible with EIP1559
      hardfork: process.env.CODE_COVERAGE ? "berlin" : "london",
    },
    baobab: {
      chainId: 1001,
      url: "https://public-node-api.klaytnapi.com/v1/baobab",
      accounts,
      gasPrice: 250000000000,
    },
    cypress: {
      chainId: 8217,
      url: "https://public-node-api.klaytnapi.com/v1/cypress",
      accounts,
      gasPrice: 250000000000,
    },
  },
  paths: {
    artifacts: "artifacts",
    cache: "cache",
    deploy: "deploy",
    deployments: "deployments",
    imports: "imports",
    sources: "contracts",
    tests: "test",
  },
  solidity: {
    compilers: [
      {
        version: "0.8.1",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      {
        version: "0.8.2",
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      {
        version: "0.8.8",
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
    ],
    settings: {
      outputSelection: {
        "*": {
          "*": ["storageLayout"],
        },
      },
    },
  },
  typechain: {
    outDir: "types",
    target: "ethers-v5",
  },
  mocha: {
    timeout: 300000,
  },
  abiExporter: {
    path: "deployments/abis",
    runOnCompile: true,
    clear: true,
    flat: true,
    spacing: 2,
    pretty: false,
  },
};
