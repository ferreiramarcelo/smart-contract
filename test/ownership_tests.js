let LATToken = artifacts.require("LATToken");

const assertFail = require("./helpers/assertFail");

let latToken;
let contribution;

contract("LATToken", function(accounts) {
  beforeEach(async () => {
    latToken = await LATToken.new();
  });

  it("Deployer is founder", async () => {
    assert.equal(await(latToken.founder.call()), accounts[0]);
  });

  it("Founder can change founder", async () => {
    await latToken.changeFounder(accounts[1]);
    assert.equal(await(latToken.founder.call()), accounts[1]);
  });

  it("Founder can set minter", async () => {
    await latToken.changeMinter(accounts[1]);
    assert.equal(await(latToken.minter.call()), accounts[1]);
  });

  it("Founder can change exchanger", async () => {
    await latToken.changeExchanger(accounts[1]);
    assert.equal(await(latToken.exchanger.call()), accounts[1]);
  });

  it("Non-founder cannot change founder", async () => {
    await assertFail(async () => {
      await latToken.changeFounder(accounts[1], {
        from: accounts[1]
      });
    });
  });

  it("Non-founder cannot set minter", async () => {
    await assertFail(async () => {
      await latToken.changeMinter(accounts[1], {
        from: accounts[1]
      });
    });
  });

  it("Non-founder cannot change exchanger", async () => {
    await assertFail(async () => {
      await latToken.changeExchanger(accounts[1], {
        from: accounts[1]
      });
    });
  });
});
