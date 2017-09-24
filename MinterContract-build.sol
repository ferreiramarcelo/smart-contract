pragma solidity ^0.4.12;

/*

contract SafeMath - mathematics with overflow checks
contract Token - abstract ERC20 token
contract StandardToken - default realization of ERC20 token
contract LATToken - realization of ERC20-based LAT Token
contract ExchangeContract - contract-helper to support exchanging old tokens to the new ones (if it will be needed in future)

This smart contract (LATokenMinter) realizes base logic of minting the LAT Tokens:
1. Send 400 000 000 of LAT tokens to the company wallet on the Token Sale ending
2. Starting from 22.08.2022 smart contract will everyday send 328 767 LAT to the company wallet in next 5 years. It will send 600 000 000 tokens in total.

*/


/**
 * Math operations with safety checks
 */
contract SafeMath {
	function mul(uint a, uint b) internal returns (uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint a, uint b) internal returns (uint) {
		assert(b > 0);
		uint c = a / b;
		assert(a == b * c + a % b);
		return c;
	}

	function sub(uint a, uint b) internal returns (uint) {
		assert(b <= a);
		return a - b;
	}

	function add(uint a, uint b) internal returns (uint) {
		uint c = a + b;
		assert(c >= a);
		return c;
	}

	function assert(bool assertion) internal {
		if (!assertion) {
			revert();
		}
	}
}
// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens, after that function `receiveApproval`
    /// @notice will be called on `_spender` address
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @param _extraData Some data to pass in callback function
    /// @return Whether the approval was successful or not
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Issuance(address indexed _to, uint256 _value);
    event Burn(address indexed _from, uint256 _value);
}

/*
Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
.*/


contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        string memory signature = "receiveApproval(address,uint256,address,bytes)";

        if (!_spender.call(bytes4(bytes32(sha3(signature))), msg.sender, _value, this, _extraData)) {
            revert();
        }

        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}


contract LATToken is StandardToken, SafeMath {

    /* Public variables of the token */

    address     public founder;
    address     public minter = 0;
    address     public exchanger = 0;

    string      public name             =       "LAT Token";
    uint8       public decimals         =       6;
    string      public symbol           =       "LAT";
    string      public version          =       "0.7.1";


    modifier onlyFounder() {
        if (msg.sender != founder) {
            revert();
        }
        _;
    }

    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert();
        }
        _;
    }

    function transfer(address _to, uint256 _value) returns (bool success) {

        if (exchanger && _to == exchanger) {
            assert(ExchangeContract(exchanger).exchange(msg.sender, _value));
            return true;
        }

        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {

            balances[msg.sender] = sub(balances[msg.sender], _value);
            balances[_to] = add(balances[_to], _value);

            Transfer(msg.sender, _to, _value);
            return true;

        } else {
            return false;
        }
    }

    function issueTokens(address _for, uint tokenCount)
        external
        payable
        onlyMinter
        returns (bool)
    {
        if (tokenCount == 0) {
            return false;
        }

        totalSupply = add(totalSupply, tokenCount);
        balances[_for] = add(balances[_for], tokenCount);
        Issuance(_for, tokenCount);
        return true;
    }

    function burnTokens(address _for, uint tokenCount)
        external
        onlyMinter
        returns (bool)
    {
        if (tokenCount == 0) {
            return false;
        }

        if (sub(totalSupply, tokenCount) > totalSupply) {
            revert();
        }

        if (sub(balances[_for], tokenCount) > balances[_for]) {
            revert();
        }

        totalSupply = sub(totalSupply, tokenCount);
        balances[_for] = sub(balances[_for], tokenCount);
        Burn(_for, tokenCount);
        return true;
    }

    function changeMinter(address newAddress)
        public
        onlyFounder
        returns (bool)
    {   
        minter = newAddress;
    }

    function changeFounder(address newAddress)
        public
        onlyFounder
        returns (bool)
    {   
        founder = newAddress;
    }

    function changeExchanger(address newAddress)
        public
        onlyFounder
        returns (bool)
    {   
        exchanger = newAddress;
    }

    function () payable {
        throw;
    }

    function LATToken() {
        founder = msg.sender;
        totalSupply = 0;
    }

    function assert(bool x) internal {
        if (!x) throw;
    }
}



contract ExchangeContract {

	address public founder;
	uint256 public prevCourse;
	uint256 public nextCourse;

	address public prevTokenAddress;
	address public nextTokenAddress;

	LATToken public prevToken;
	LATToken public nextToken;

	modifier onlyFounder() {
        if (msg.sender != founder) {
            revert();
        }
        _;
    }

    modifier onlyPreviousToken() { 
    	if (msg.sender != prevTokenAddress) {
            revert();
        }
        _;
    }
    
	function changeCourse(uint256 _prevCourse, uint256 _nextCourse)
		public
		onlyFounder
	{
		prevCourse = _prevCourse;
		nextCourse = _nextCourse;
	}

	function exchange(address _for, uint256 prevTokensAmount)
		public
		onlyPreviousToken 
		returns (bool)
	{
		// проверить на отсылаемого
		if (prevToken.balanceOf(_for) >= prevTokensAmount) {
			uint256 amount = prevTokensAmount / prevCourse;

			assert(prevToken.burnTokens(_for, amount * prevCourse));
			assert(nextToken.issueTokens(_for, amount * nextCourse));

			return true;
		} else {
			revert();
		}
	}

	function ExchangeContract(address _prevTokenAddress, address _nextTokenAddress, uint256 _prevCourse, uint256 _nextCourse) {
		founder = msg.sender;

		prevTokenAddress = _prevTokenAddress;
		nextTokenAddress = _nextTokenAddress;

		prevToken = LATToken(_prevTokenAddress);
		nextToken = LATToken(_nextTokenAddress);

		prevCourse = _prevCourse;
		nextCourse = _nextCourse;
	}

	function assert(bool x) internal {
        if (!x) throw;
    }

}


contract LATokenMinter is SafeMath {

    LATToken public token; // Token contract
    
    address public founder; // Address of founder
    address public helper;  // Address of helper

    address public teamPoolInstant; // Address of team pool for instant issuance after token sale end
    address public teamPoolForFrozenTokens; // Address of team pool for smooth unfroze during 5 years after 5 years from token sale start

    bool public teamInstantSent = false; // Flag to prevent multiple issuance for team pool after token sale

    uint public contributorsTotalBalance; // Total tokens issued for contributors

    uint public contributorsHardCap = 200000000; // Hard cap of tokens during token sale

    uint public startTime;            // Unix timestamp of start
    uint public endTime;              // Unix timestamp of end
    uint public numberOfDays;         // Number of windows after 0
    uint public unfrozePerDay;        // Tokens sold in each window

    mapping (uint => bool) public harvested; // Mapping with indicators of which days was harvested for unfrozen tokens or not

    /*
     *  Modifiers
     */
    modifier onlyFounder() {
        // Only founder is allowed to do this action.
        if (msg.sender != founder) {
            revert();
        }
        _;
    }

    modifier onlyHelper() {
        // Only helper is allowed to do this action.
        if (msg.sender != helper) {
            revert();
        }
        _;
    }

    function fundTeamInstant()
        external
        onlyFounder
        returns (bool)
    {
        if (teamInstantSent) {
            throw;
        }

        // 200 mln
        uint totalInstantAmount = 400000000;

        if (!token.issueTokens(teamPoolInstant, totalInstantAmount)) {
            throw;
        }

        teamInstantSent = true;
        return true;
    }

    function fundManually(address beneficiary, uint _tokenCount)
        external
        onlyHelper
        returns (uint)
    {
        if (!token.issueTokens(beneficiary, _tokenCount)) {
            revert();
        } else {
            contributorsTotalBalance = add(contributorsTotalBalance, _tokenCount);
        }

        return _tokenCount;
    }

    function changeTokenAddress(address newAddress)
        external
        onlyFounder
        returns (bool)
    {
        token = LATToken(newAddress);
        return true;
    }

    function changeFounder(address newAddress)
        external
        onlyFounder
        returns (bool)
    {   
        founder = newAddress;
        return true;
    }

    function changeHelper(address newAddress)
        external
        onlyFounder
        returns (bool)
    {   
        helper = newAddress;
        return true;
    }

    function changeTeamPoolInstant(address newAddress)
        external
        onlyFounder
        returns (bool)
    {   
        teamPoolInstant = newAddress;
        return true;
    }

    function changeTeamPoolForFrozenTokens(address newAddress)
        external
        onlyFounder
        returns (bool)
    {   
        teamPoolForFrozenTokens = newAddress;
        return true;
    }

    function harvest()
        external
        onlyHelper
        returns (uint)
    {
        uint currentTimeDiff = now - startTime;
        uint currentDay = currentTimeDiff / (24 * 3600);

        if (now >= endTime) {
            currentTimeDiff = endTime - startTime + 1;
            currentDay = 5 * 365 - 1;
        }

        uint harvestedTotal = 0;

        for (uint i = 0; i <= currentDay; i++) {
            if (!harvested[i]) {
                if (!token.issueTokens(teamPoolForFrozenTokens, unfrozePerDay)) {
                    throw;
                }
                harvestedTotal = add(harvestedTotal, unfrozePerDay);
                harvested[i] = true;
            }
        }

        return harvestedTotal;
    }

    function LATokenMinter(address _LATTokenAddress, address _helperAddress) {
        founder = msg.sender;
        helper = _helperAddress;
        token = LATToken(_LATTokenAddress);

        numberOfDays = 5 * 365; // 5 years
        startTime = 1503399600; // 22 august 2017 11:00 GMT+0;
        endTime = startTime + numberOfDays * 1 days;

        uint frozenTokens = 600000000;

        unfrozePerDay = frozenTokens / numberOfDays;
        
        for (uint i = 0; i < numberOfDays; i++) {
            harvested[i] = false;
        }
    }

    function () payable {
        throw;
    }
}
