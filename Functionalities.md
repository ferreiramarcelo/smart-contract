# Smart Contract goals and restrictions
 
## Goals
1.  Creation of ERC20-compatible (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md) LAT tokens available for storing in Ethereum-compatible wallets and trading on cryptoexchanges
2.  Issuance of 400 000 000 tokens to the address of company pool. Part of this tokens will be used for distribution of tokens for contributors (about 11000 contributors).
3.  Starting from 22 August 2022 issuance of 600 000 000 will start and will last next 5 years. Every day equal amount of tokens (328,767.12328767126 tokens) will be sent to the address of company pool until all 600 000 000 tokens is issued.
## Restrictions
1. By “execution” or “calling” specified function here and below will be meant process of sending signed transaction which will cause EVM to process block of code marked as a function with specified name. Transaction must be signed using private key of some Ethereum-address (and entering password of this key if necessary), used address is called “executor” or “caller” of function.
2. All addresses (founder, token, minter, exchanger, helper) in smart contracts should be changeable in terms of having ability to upgrade and fix anything. They should be changeable ONLY by founder and by no one else.
3. Founder is set as the address of the smart contract deployer. After that, new founder can only be set by the previous founder (using function changeFounder)
4. Only “minter” and “exchanger” can issue and burn tokens
5. Only “helper” can initialize issuance of tokens for company pool during unfrozing period
6. Only account owner can transfer tokens from his account, except cases when he allowed someone to do so with certain amount of tokens by executing approve function with 2 arguments: address of spender (someone who will transfer tokens on your behalf) and amount of tokens (spender will be allowed to spend only up to this amount in total).
# Overview
 
### Project consists 3 internal libraries:
1.    [Token.sol][lib1] – abstract contract for ERC20 tokens with necessary functions declarations without any internal logic
2.    [StandardToken.sol][lib2] – implementation of ERC20 token with all necessary logic (described below)
3.    [SafeMath.sol][lib3] – provides all mathematical operations on uint256 with safety checks (basically overflow checks).
 
### And 3 base parts:
1.    LATToken.sol - Smart contract of ERC20 token itself
2.    LATokenMinter.sol - Smart contract of minter – contract which responsible for issuing tokens
3.    ExchangeContract.sol - Smart contract of exchanger – contract which can automatically convert old tokens which were sent to it to the new tokens
 
# Detailed view
 
## Token.sol
No internal logic
## StandardToken.sol
#### Function transfer
Transfers specified amount of tokens from caller to specified address with balances checks and creation of Transfer event.
#### Function transferFrom
Transfers specified amount of tokens from specified address to other specified address with creating Transfer event. There are checks for allowance (are you able to do such transfer), and for balances (is there enough balances on addresses).
#### Function balanceOf
Returns amount of tokens for the specified address
#### Function approve
Sets allowance for specified address for specified amount of tokens from caller with creating Approval event.
#### Function approveAndCall
Sets allowance for specified address for specified amount of tokens from caller with creating Approval event and calling receiveApproval function on the smart contract receiving allowance.
#### Function allowance
Returns amount of allowance from specified address to specified address.
 
## SafeMath.sol
#### Function mul
Multiplies 2 numbers and checks if the result is correct
#### Function div
Divides first number by second number and checks if the result is correct
#### Function sub
Subtracts second number from first number and checks if the result is correct
#### Function add
Adds second number to first number and checks if the result is correct
 
## LATToken.sol
At the deployment, contract saves deployer address as a founder address and sets totalSupply value to zero.
#### Variable founder
Consists address of wallet/smart contract which can execute “onlyFounder” functions in the contract
#### Variable minter
Consists address of wallet/smart contract which can execute “onlyMinterAndExchanger” functions in the contract
#### Variable exchanger
Consists address of wallet/smart contract which can execute “onlyMinterAndExchanger” functions in the contract
#### Variable name
Consists string “LAT Token” – used by wallets to show name of token, not used in contract internally
#### Variable decimals
Consists number 18 – used by wallets to differentiate integer and fractional parts of a number in all places where amount of tokens showed, not used in contract internally
#### Variable symbol
Consists string “LAT” – used by wallets and exchanges to show symbol of token, not used in contract internally
#### Variable version
Consists string “0.7.1” – used by wallets to show version of token, not used in contract internally
#### Modifier onlyFounder
When used on the function rejects all the executions except from the founder address
#### Modifier onlyMinterAndExchanger
When used on the function rejects all executions except from the minter or exchanger addresses
#### Function transfer
Expansion of standart ERC20 transfer function – when transfering goes to the “exchanger” address it will not change balances by itself, but will call “exchange” function of the exchanger contract passing specified address and specified amount to it.
#### Function issueTokens
This function can be executed only by minter or exchanger. It adds specified amount of tokens to the balance of specified address and totalSupply variable and creates Issuance event
#### Function burnTokens
This function can be executed only by minter or exchanger. It subtracts specified amount of tokens from the balance of specified address and totalSupply variable and creates Burn event
#### Function changeMinter
This function can be executed only by founder. It replaces current minter address by the specified new address
#### Function changeExchanger
This function can be executed only by founder. It replaces current exchanger address by the specified new address
#### Function changeFounder
This function can be executed only by founder. It replaces current founder address by the specified new address
 
## LATokenMinter.sol
On the deployment contract saves deployer address as a founder address and saves specified token and helper addresses.
#### Variable founder
Consists address of wallet/smart contract which can execute “onlyFounder” functions in the contract
#### Variable helper
Consists address of wallet/smart contract which can execute “onlyHelper” (harvest) functions in the contract
#### Variable token
Consists address of LATToken contract, used for issuance of tokens
#### Variable teamPoolInstant
Consists address of wallet/smart contract which will receive 400 000 000 tokens after deployment and executing “fundTeamInstant”
#### Variable teamPoolForFrozenTokens
Consists address of wallet/smart contract which will receive 600 000 000 tokens in 5 years starting from 22 August 2022
#### Variable teamInstantSent
Flag to prevent multiple executing of “fundTeamInstant” – by default it consists “false” value, right after the execution of “fundTeamInstant” – it will consist “true” value.
#### Variable startTime
Unix timestamp with the starting date of frozen tokens issuance
#### Variable endTime
Unix timestamp with the ending date of frozen tokens issuance, it should be equal: startTime + 5 * 365 days
#### Variable numberOfDays
Number of days during which the frozen tokens will be issued. Should be equal - 5 * 365.
#### Variable unfrozePerDay
Number of tokens issued each day of 5 years unfrozing period. Should be equal: 600 000 000 / (5 * 365) = 328 767 LAT
#### Variable alreadyHarvestedTokens
Amount of tokens that were already unfrozen and issued to “teamPoolForFrozenTokens” address
#### Modifier onlyFounder
When used on the function rejects all the executions except from the founder address
#### Modifier onlyHelper
When used on the function rejects all executions except from the helper
#### Function fundTeamInstant
Function can be executed only 1 time (checked by teamInstantSent flag). It issues 400 000 000 LAT to the address “teamPoolInstant”.
#### Function harvest
This function should be called everyday after 22 August of 2022. By each execution it calculates whole amount of tokens that unfrozen, subtracts from it amount of tokens that were already sent (“alreadyHarvestedTokens”), sends unharvested unfrozen tokens to “teamPoolForFrozenTokens” and updates “alreadyHarvestedTokens” variable by adding to it amount of issued tokens.
#### Function changeTokenAddress
This function can be executed only by founder. It replaces current token address by the specified new address
#### Function changeHelper
This function can be executed only by founder. It replaces current helper address by the specified new address
#### Function changeTeamPoolInstant
This function can be executed only by founder. It replaces current teamPoolInstant address by the specified new address
#### Function changeTeamPoolForFrozenTokens
This function can be executed only by founder. It replaces current teamPoolForFrozenTokens address by the specified new address
#### Function changeFounder
This function can be executed only by founder. It replaces current founder address by the specified new address
 
## ExchangeContract.sol
At the deployment, contract saves deployer address as a founder address, saves specified previous token and next token addresses, saves previous token price (prevCourse) and next token price (nextCourse).
#### Variable founder
Consists address of wallet/smart contract which can execute “onlyFounder” functions in the contract
#### Variable prevTokenAddress
Consists address of smart contract of the token which will be replaced by next token
#### Variable nextTokenAddress
Consists address of smart contract of the token which is replacing previous token
#### Variable prevCourse
Consists price of previous token
#### Variable nextCourse
Consists price of next token
#### Modifier onlyFounder
When used on the function rejects all the executions except from the founder address
#### Modifier onlyPreviousToken
When used on the function rejects all executions except from the previous token address
#### Function exchange
This function can be called only by previous token. It should be called automatically if someone wants to send tokens to the exchanger address. It calculates amount of next tokens by dividing amount of previous tokens someone wants to exchange by previous token price and multiplying by next token price.
After that it burns specified amount of previous tokens and issues calculated amount of next tokens for specified address (with all balances checks).
#### Function changeCourse
Saves new prices of previous and next token
#### Function changeFounder
This function can be executed only by founder. It replaces current founder address by the specified new address

[lib1]: https://github.com/LAToken/smart-contract/blob/master/contracts/base-token/Token.sol
[lib2]: https://github.com/LAToken/smart-contract/blob/master/contracts/base-token/StandardToken.sol
[lib3]: https://github.com/LAToken/smart-contract/blob/master/contracts/lib/SafeMath.sol