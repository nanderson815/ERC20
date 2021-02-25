const path = require("path");
const fs = require("fs");
const solc = require("solc");

const contractPath = path.resolve(__dirname, "contracts", "Token.sol");
const source = fs.readFileSync(contractPath, "UTF-8");

var input = {
  language: "Solidity",
  sources: {
    "Token.sol": {
      content: source,
    },
  },
  settings: {
    outputSelection: {
      "*": {
        "*": ["*"],
      },
    },
  },
};
console.log(
  JSON.parse(solc.compile(JSON.stringify(input))).contracts["Token.sol"]
);
module.exports = JSON.parse(solc.compile(JSON.stringify(input))).contracts[
  "Token.sol"
]["Token"];
