# Smart Contract goals and restrictions
 
## Goals
1.  Create ERC20-compatible (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md) LAT token available for storage in Ethereum-compatible wallets and trading on cryptoexchanges
2.  Issue 400 000 000 tokens to the company pool address, including tokens for further distribution to contributors (more than 15000 contributors).
3.  Start issuing tokens from the reserve pool ("frozen tokens") on 22 August 2022. Tokens from the reserve pool will be issued every day in equal amounts (328,767.12328767126 tokens) and sent to the company pool address for 5 years starting from 22.08.2022 until all 600 000 000 tokens are issued.
## Restrictions
1. By “execution” or “calling” a function is meant a process of sending a signed transaction which will cause EVM (Ethereum Virtual Machine) to process block of code marked as a function with specified name. The transaction must be signed using a private key of an Ethereum-address (and entering the password for this key if necessary), the Ethereum-address used is called “executor” or “caller” of the function.
2. All addresses (founder, token, minter, exchanger, helper) in smart contracts can be updated ONLY by founder and by no one else.
3. The founder is set as the address of the smart contract deployer. After that, new founder can only be set by the previous founder (using function changeFounder)
4. Only “minter” and “exchanger” can issue and burn tokens
5. Only “helper” can initialize the issuance of tokens from the reserve pool to the company pool address and only starting from 22.08.2022.
6. Only account owner can transfer tokens from his account, except cases when he entitles someone to do so by executing function "approve" with 2 arguments: address of spender (someone who will transfer tokens on your behalf) and number of tokens (spender will be allowed to spend only up to this amount in total).
# Overview
 
### Project contains 3 internal libraries:
1.    [Token.sol][lib1] – abstract contract for ERC20 token with necessary functions' declarations without any internal logic
2.    [StandardToken.sol][lib2] – implementation of ERC20 token with the necessary logic (described below)
3.    [SafeMath.sol][lib3] – contract providing all mathematical operations on uint256 with safety checks (basically overflow checks).
 
### And 3 base parts:
1.    LATToken.sol - Smart contract of ERC20 token itself
2.    LATokenMinter.sol - Smart contract of minter – a contract which responsible for issuing tokens
3.    ExchangeContract.sol - Smart contract of exchanger – a contract which can automatically convert old tokens sent to it to the new tokens
 
# Detailed view
 
## Token.sol
No internal logic
## StandardToken.sol
#### Function transfer
Transfers a specified number of tokens from caller to a specified address checking balances and creating the Transfer event.
#### Function transferFrom
Transfers a specified number of tokens from one specified address to another creating the Transfer event. There are checks for allowance (are you able to do such transfer) and for the balance (is there a sufficient balance at the address).
#### Function balanceOf
Returns the number of tokens for the specified address
#### Function approve
Sets allowance from caller to a specified address for a specified number of tokens creating Approval event.
#### Function approveAndCall
Sets allowance from caller to a specified address for a specified number of tokens creating Approval event and calling receiveApproval function on the smart contract receiving allowance.
#### Function allowance
Returns the amount of allowance given from one specified address to another.
 
## SafeMath.sol
#### Function mul
Multiplies two numbers and checks if the result is correct
#### Function div
Divides the first number by the second number and checks if the result is correct
#### Function sub
Subtracts the second number from the first number and checks if the result is correct
#### Function add
Adds the second number to the first number and checks if the result is correct
 
## LATToken.sol
At the deployment the contract saves deployer’s address as the founder’s address and sets totalSupply value to zero.
#### Variable founder
Contains address of wallet/smart contract which can execute “onlyFounder” function in the contract
#### Variable minter
Contains address of wallet/smart contract which can execute “onlyMinterAndExchanger” function in the contract
#### Variable exchanger
Contains address of wallet/smart contract which can execute “onlyMinterAndExchanger” function in the contract
#### Variable name
Contains the string “LAT Token” – used by wallets to show the name of token. Not used in contract internally
#### Variable decimals
Contains the number 18 – used by wallets to differentiate an integer and fractional part of a number in all places where the number of tokens is showed. Not used in contract internally
#### Variable symbol
Contains the string “LAT” – used by wallets and exchanges to show the token symbol. Not used in contract internally
#### Variable version
Contains the string “0.7.1” – used by wallets to show the token version. Not used in contract internally
#### Modifier onlyFounder
Applied to the function rejects all executions except those from the founder’s address
#### Modifier onlyMinterAndExchanger
Applied to the function rejects all executions except those from the minter’s or exchanger’s addresses
#### Function transfer
Expansion of a standard ERC20 transfer function – when transfer goes to the “exchanger” address it will not change the balance by itself, but will call “exchange” function of the exchanger’s contract passing the specified address and specified amount to it.
#### Function issueTokens
This function can be executed only by minter or exchanger. It adds the specified number of tokens to the balance of the specified address and to the “totalSupply” variable and creates the Issuance event
#### Function burnTokens
This function can be executed only by minter or exchanger. It subtracts the specified number of tokens from the balance of the specified address and from “totalSupply” variable and creates the Burn event
#### Function changeMinter
This function can be executed only by the founder. It replaces the current minter’s address with the specified new address
#### Function changeExchanger
This function can be executed only by the founder. It replaces the current exchanger’s address with the specified new address
#### Function changeFounder
This function can be executed only by the founder. It replaces the current founder’s address with the specified new address
 
## LATokenMinter.sol
At the deployment the contract saves the deployer’s address as a founder’s address and saves specified token’s and helper’s addresses.
#### Variable founder
Contains the address of a wallet/smart contract which can execute “onlyFounder” function in the contract
#### Variable helper
Contains the address of a wallet/smart contract which can execute “onlyHelper” (harvest) function in the contract
#### Variable token
Contains the address of LATToken contract, used for issuance of tokens
#### Variable teamPoolInstant
Contains the address of a wallet/smart contract which will receive 400 000 000 tokens after deployment and executing “fundTeamInstant”
#### Variable teamPoolForFrozenTokens
Contains the address of a wallet/smart contract which will receive 600 000 000 tokens during 5 years starting from 22 August 2022
#### Variable teamInstantSent
Flag to prevent multiple execution of “fundTeamInstant” – by default it contains “false” value, right after the execution of “fundTeamInstant” it will contain “true” value.
#### Variable startTime
Unix timestamp with the starting date of the frozen tokens issuance
#### Variable endTime
Unix timestamp with the end date of the frozen tokens issuance, it should be equal: startTime + 5 * 365 days
#### Variable numberOfDays
Number of days during which the frozen tokens will be issued. Should be equal - 5 * 365.
#### Variable unfrozePerDay
Number of tokens issued each day after 22 August 2022. Should be equal to 600 000 000 / (5 * 365) = 328,767.12328767126 LAT
#### Variable alreadyHarvestedTokens
Number of tokens already unfrozen and issued to “teamPoolForFrozenTokens” address
#### Modifier onlyFounder
Applied to the function rejects all the executions except those from the founder’s address
#### Modifier onlyHelper
Applied to the function rejects all executions except those from the helper
#### Function fundTeamInstant
The function can be executed only once (checked by teamInstantSent flag). It issues 400 000 000 LAT to the address “teamPoolInstant”.
#### Function harvest
This function should be called once a day after 22 August of 2022. By each execution it calculates the number of unfrozen tokens, subtracts from it the number of already issued tokens (“alreadyHarvestedTokens”), sends unharvested unfrozen tokens to “teamPoolForFrozenTokens” and adds the number of issued tokens to “alreadyHarvestedTokens” variable.
#### Function changeTokenAddress
This function can be executed only by the founder. It replaces the current token’s address by the specified new address
#### Function changeHelper
This function can be executed only by the founder. It replaces the current helper’s address by the specified new address
#### Function changeTeamPoolInstant
This function can be executed only by the founder. It replaces the current teamPoolInstant address by the specified new address
#### Function changeTeamPoolForFrozenTokens
This function can be executed only by the founder. It replaces the current teamPoolForFrozenTokens address by the specified new address
#### Function changeFounder
This function can be executed only by founder. It replaces the current founder address by the specified new address
 
## ExchangeContract.sol
At the deployment the contract saves the deployer’s address as a founder address, saves a specified previous token’s and the next token’s addresses, saves a previous token price (prevCourse) and the next token price (nextCourse).
#### Variable founder
Contains the address of wallet/smart contract which can execute “onlyFounder” functions in the contract
#### Variable prevTokenAddress
Contains the address of a smart contract of the token which will be replaced by the next token
#### Variable nextTokenAddress
Contains the address of a smart contract of the token which is replacing a previous token
#### Variable prevCourse
Contains the price of a previous token
#### Variable nextCourse
Contains a price of the next token
#### Modifier onlyFounder
Applied to the function rejects all executions except those from the founder’s address
#### Modifier onlyPreviousToken
Applied to the function rejects all executions except those from the previous token address
#### Function exchange
This function can be called only by the previous token. It should be called automatically if someone wants to send tokens to the exchanger address. It calculates the number of next tokens by dividing the number of previous tokens someone wants to exchange by the previous token price and multiplying it by the next token price. After that it burns a specified number of previous tokens and issues the calculated number of the next tokens to the specified address (with all balance checks).
#### Function changeCourse
Saves new prices of the previous and next tokens
#### Function changeFounder
This function can be executed only by the founder. It replaces the current founder’s address by the specified new address

[lib1]: https://github.com/LAToken/smart-contract/blob/master/contracts/base-token/Token.sol
[lib2]: https://github.com/LAToken/smart-contract/blob/master/contracts/base-token/StandardToken.sol
[lib3]: https://github.com/LAToken/smart-contract/blob/master/contracts/lib/SafeMath.sol