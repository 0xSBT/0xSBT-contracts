const HDWalletProvider = require("truffle-hdwallet-provider-klaytn");

module.exports = {
    networks: {
        baobab: {
            provider: () => { return new HDWalletProvider("0x9ad314ad9a83ad78369fb481145b9a3abc37d7f4c163b2ec665e9933127564d5", "https://api.baobab.klaytn.net:8651") },
            network_id: '1001', //Klaytn baobab testnet's network id
            gas: '5000000',
            gasPrice: null
        },
    },

    // Set default mocha options here, use special reporters etc.
    mocha: {
        // timeout: 100000
    },

    // Configure your compilers
    compilers: {
        solc: {
            version: "0.8.1" // Specify compiler's version to 0.5.6
        }
    }
}