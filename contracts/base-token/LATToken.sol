pragma solidity ^0.4.15;

import "./StandardToken.sol";
import "../lib/SafeMath.sol";
import "../ExchangeContract.sol";

contract LATToken is StandardToken {
    using SafeMath for uint256;
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

            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);

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

        totalSupply = totalSupply.add(tokenCount);
        balances[_for] = balances[_for].add(tokenCount);
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

        if (totalSupply.sub(tokenCount) > totalSupply) {
            revert();
        }

        if (balances[_for].sub(tokenCount) > balances[_for]) {
            revert();
        }

        totalSupply = totalSupply.sub(tokenCount);
        balances[_for] = balances[_for].sub(tokenCount);
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
}
