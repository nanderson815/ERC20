const assert = require("assert");
const ganache = require("ganache-cli");
const Web3 = require("web3");
const compiled = require("../compile");

const web3 = new Web3(ganache.provider());
let accounts;
let Token;

// beforeEach(async () => {
//   // Get a list of all accounts
//   accounts = await web3.eth.getAccounts();

//   // Use an account to deploy contract
//   inbox = await new web3.eth.Contract(compiled.abi)
//     .deploy({
//       data: compiled.evm.bytecode.object,
//       arguments: ["Hi there!!"],
//     })
//     .send({ from: accounts[0], gas: "1000000" });
// });

// describe("Inbox", () => {
//   it("deploys a contract", () => {
//     assert.ok(inbox.options.address);
//   });
//   it("has a default message", async () => {
//     const message = await inbox.methods.message().call();
//     assert.strictEqual(message, "Hi there!!");
//   });
//   it("can modify the message", async () => {
//     await inbox.methods.setMessage("whats poppin").send({ from: accounts[0] });
//     const message = await inbox.methods.message().call();
//     assert.strictEqual(message, "whats poppin");
//   });
// });
