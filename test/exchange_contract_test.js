let ExchangeContract = artifacts.require("ExchangeContract");
let LATToken = artifacts.require("LATToken");

const assertFail = require("./helpers/assertFail");

let exchangeContract;
let contribution;

let prevToken, nextToken;
let prevCourse = 1;
let nextCourse = 3;

contract("ExchangeContract", function(accounts) {
  beforeEach(async () => {
    prevToken = await LATToken.new();
    nextToken = await LATToken.new();

    exchangeContract = await ExchangeContract.new(prevToken.address, nextToken.address, prevCourse, nextCourse);
  });

  it("Double check next course", async () => {
    assert.equal((await exchangeContract.nextCourse.call()).toNumber(), 3);
  });

  it("Test Exchange", async () => {

    await prevToken.changeMinter(accounts[0]);
    await prevToken.issueTokens(accounts[0], 10000);
    await prevToken.changeExchanger(exchangeContract.address);

    await prevToken.transfer(exchangeContract.address, 10000, {
      from: accounts[0]
    });

    assert.equal(
      (await prevToken.balanceOf.call(accounts[0])).toNumber(),
      0
    );

    assert.equal(
      (await nextToken.balanceOf.call(accounts[0])).toNumber(),
      30000
    );
  });

});
