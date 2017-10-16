# LA Token Contracts

[![Coverage Status](https://coveralls.io/repos/github/BlockchainLabsNZ/LAToken-Contracts-Audit/badge.svg?branch=master)](https://coveralls.io/github/BlockchainLabsNZ/LAToken-Contracts-Audit?branch=master) [![Build Status](https://travis-ci.org/BlockchainLabsNZ/LAToken-Contracts-Audit.svg?branch=master)](https://travis-ci.org/BlockchainLabsNZ/LAToken-Contracts-Audit)

The smart contracts for the [LA Token][latoken] token (LAT) crowdsale.

![LA Token](LA_Token.png)

## Smart Contracts content and functionalities

Please see the [full document][fulldoc] to find any information on this smart contracts.

## Contracts

Please see the [contracts/](contracts) directory.

## Build

After the Token Sale the `LATToken.sol`, `LATokenMinter.sol` and `ExchangeContract.sol` will be deployed. The supply of 400,000,000 LAT will be minted and stored in the `teamPoolInstant` address.

200,000,000 of this tokens will be stored in the company pool and other 200,000,000 will be used for distribution of tokens to contributors. Every contributor will be able to request withdrawal from the LAT Wallet (wallet.latoken.com) and receive their LAT as ERC20 tokens in Ethereum.

Other 600,000,000 of tokens will be frozen in the next 5 years. 

After 5 years, on 22th August, 2022 the distribution of frozen tokens will start and last for the next 5 years.
Every day a fixed amount of tokens (about 328,767 LAT) will be available for harvesting to the `teamPoolForFrozenTokens`.

After 10 years the total supply will be 1,000,000,000 LAT.

## Develop

Contracts are written in [Solidity][solidity] and tested using [Truffle][truffle] and [testrpc][testrpc].

### Install

```bash
# Install dependencies:
$ npm install
```

### Test
```bash
$ npm test
```

[fulldoc]: https://github.com/LAToken/smart-contract/blob/master/Functionalities.md
[latoken]: https://latoken.com/

[solidity]: https://solidity.readthedocs.io/en/develop/
[truffle]: http://truffleframework.com/
[testrpc]: https://github.com/ethereumjs/testrpc
