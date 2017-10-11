let LATminter = artifacts.require("LATokenMinterMock");
let LATtoken = artifacts.require("LATToken");
const assertFail = require("./helpers/assertFail");

let minter, token;
const minute = 60
const hour = 60 * minute;
const day = 24 * hour;

const minterStartTime = 1661166000; // This comes from the LATToken constructor
const tokenPerDay = 328767123287;

contract("LATokenMinter", function(accounts) {
  beforeEach(async () => {
    token = await LATtoken.new();
    minter = await LATminter.new(token.address, accounts[0]);
    await token.changeMinter(minter.address);
    await minter.changeTeamPoolForFrozenTokens(accounts[1]);
  });

  it("Harvest function works correctly", async () => {
    assert.equal((await token.balanceOf.call(accounts[1])).toNumber(), 0);
    await minter.setBlockTimestamp(minterStartTime);
    await minter.harvest();
    assert.equal((await token.balanceOf.call(accounts[1])).toNumber(), tokenPerDay);
    await minter.setBlockTimestamp(minterStartTime + (1 * day));
    await minter.harvest();
    assert.equal((await token.balanceOf.call(accounts[1])).toNumber(), tokenPerDay * 2);

    await minter.setBlockTimestamp(minterStartTime + (8 * day));
    await minter.harvest();
    assert.equal((await token.balanceOf.call(accounts[1])).toNumber(), tokenPerDay * 9);

    await minter.setBlockTimestamp(minterStartTime + (365 * day));
    await minter.harvest();
    assert.equal((await token.balanceOf.call(accounts[1])).toNumber(), tokenPerDay * 366);

    await minter.setBlockTimestamp(minterStartTime + (5 * (365 * day)));
    await minter.harvest();
    assert.equal((await token.balanceOf.call(accounts[1])).toNumber(), tokenPerDay * (5 * 365));

    await assertFail(async () => { await minter.harvest() });
  });

  it("Test the onlyFounder modifier", async () => {
    assert.equal(await minter.founder.call(), accounts[0]);
    await assertFail(async () => { await minter.changeFounder(accounts[1], { from: accounts[1] }) } );
    await minter.changeFounder(accounts[1]);
    await assertFail(async () => { await minter.changeFounder(accounts[1], { from: accounts[0] }) } );
    assert.equal(await minter.founder.call(), accounts[1]);
  });

  it("Test the onlyHelper modifier", async () => {
    assert.equal(await minter.helper.call(), accounts[0]);
    await assertFail(async () => { await minter.changeHelper(accounts[1], { from: accounts[1] }) } );
    await minter.changeHelper(accounts[1]);
    assert.equal(await minter.helper.call(), accounts[1]);
  });

  it("Test the changeTokenAddress function", async () => {
    assert.equal(await minter.token.call(), token.address);
    let new_token = await LATtoken.new();
    await assertFail(async () => { await minter.changeTokenAddress(new_token.address, { from: accounts[1] }) } );
    await minter.changeTokenAddress(new_token.address);
    assert.equal(await minter.token.call(), new_token.address);
  });

  it("Test the changeTeamPoolInstant function", async () => {
    assert.equal(await minter.teamPoolInstant.call(), 0);
    await assertFail(async () => { await minter.changeTeamPoolInstant(accounts[2], { from: accounts[1] }) } );
    await minter.changeTeamPoolInstant(accounts[2]);
    assert.equal(await minter.teamPoolInstant.call(), accounts[2]);
  });

  it('the fallback function should revert unknown functions', async () => {
    await assertFail(async () => { await web3.eth.sendTransaction({
        'from': accounts[0],
        'to': minter.address,
        'value': 1
      })
    });
  });

});
