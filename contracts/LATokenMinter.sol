pragma solidity ^0.4.15;

import "./base-token/LATToken.sol";
import "./lib/SafeMath.sol";

contract LATokenMinter {
    using SafeMath for uint256;

    LATToken public token; // Token contract

    address public founder; // Address of founder
    address public helper;  // Address of helper

    address public teamPoolInstant; // Address of team pool for instant issuance after token sale end
    address public teamPoolForFrozenTokens; // Address of team pool for smooth unfroze during 5 years after 5 years from token sale start

    bool public teamInstantSent = false; // Flag to prevent multiple issuance for team pool after token sale

    uint public startTime;               // Unix timestamp of start
    uint public endTime;                 // Unix timestamp of end
    uint public numberOfDays;            // Number of windows after 0
    uint public unfrozePerDay;           // Tokens sold in each window
    uint public alreadyHarvestedTokens;  // Tokens were already harvested and sent to team pool

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
        require(!teamInstantSent);

        // 400 mln
        uint totalInstantAmount = 400000000;

        require(token.issueTokens(teamPoolInstant, totalInstantAmount));

        teamInstantSent = true;
        return true;
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
        uint currentTimeDiff = sub(now, startTime);
        uint secondsPerDay = mul(24, 3600);
        uint daysFromStart = div(currentTimeDiff, secondsPerDay);
        uint currentDay = add(daysFromStart, 1);

        if (now >= endTime) {
            currentTimeDiff = add(sub(endTime, startTime), 1);
            currentDay = mul(5, 365);
        }

        uint maxCurrentHarvest = currentDay.mul(unfrozePerDay);
        uint wasNotHarvested = maxCurrentHarvest.sub(alreadyHarvestedTokens);

        require(token.issueTokens(teamPoolForFrozenTokens, wasNotHarvested));

        alreadyHarvestedTokens = alreadyHarvestedTokens.add(wasNotHarvested);

        return wasNotHarvested;
    }

    function LATokenMinter(address _LATTokenAddress, address _helperAddress) {
        founder = msg.sender;
        helper = _helperAddress;
        token = LATToken(_LATTokenAddress);

        numberOfDays = mul(5, 365); // 5 years
        startTime = 1503399600; // 22 august 2017 11:00 GMT+0;
        endTime = add(startTime, mul(numberOfDays, 1 days));

        uint frozenTokens = 600000000;
        alreadyHarvestedTokens = 0;

        unfrozePerDay = div(frozenTokens, numberOfDays);
    }

    function () payable {
        require(false);
    }
}
