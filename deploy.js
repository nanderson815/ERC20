const HDWalletProvider = require("@truffle/hdwallet-provider");
const Web3 = require("web3");
const { abi, evm } = require("./compile");
const mnemonic = "";
const url = "";

const provider = new HDWalletProvider({
  mnemonic: {
    phrase: mnemonic,
  },
  providerOrUrl: url,
});

const web3 = new Web3(provider);

const deploy = async () => {
  const accounts = await web3.eth.getAccounts();

  console.log("accounts: ", accounts[0]);

  const result = await new web3.eth.Contract(abi)
    .deploy({
      data: evm.bytecode.object,
      arguments: ["Hi there!!"],
    })
    .send({ from: accounts[0], gas: "1000000" });

  console.log("deployed to: ", result.options.address);

  provider.engine.stop();
};

deploy();

// first deploy: 0x106984e25cFBdB7d82Ba3F587d7756F932221fE6
