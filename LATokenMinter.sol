pragma solidity ^0.4.12;

import "./base-token/LATToken.sol";
import "./lib/SafeMath.sol";

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