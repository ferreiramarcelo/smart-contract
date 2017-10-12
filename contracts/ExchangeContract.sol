pragma solidity ^0.4.15;

import "./base-token/LATToken.sol";
import "./lib/SafeMath.sol";

contract ExchangeContract {
    using SafeMath for uint256;

	address public founder;
	uint256 public prevCourse;
	uint256 public nextCourse;

	address public prevTokenAddress;
	address public nextTokenAddress;

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

    // sets new conversion rate
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

		LATToken prevToken = LATToken(prevTokenAddress);
     	LATToken nextToken = LATToken(nextTokenAddress);

		// check if balance is correct
		if (prevToken.balanceOf(_for) >= prevTokensAmount) {
			uint256 amount = prevTokensAmount.div(prevCourse);

			assert(prevToken.burnTokens(_for, amount.mul(prevCourse))); // remove previous tokens
			assert(nextToken.issueTokens(_for, amount.mul(nextCourse))); // give new ones

			return true;
		} else {
			revert();
		}
	}

	function changeFounder(address newAddress)
        external
        onlyFounder
        returns (bool)
    {
        founder = newAddress;
        return true;
    }

	function ExchangeContract(address _prevTokenAddress, address _nextTokenAddress, uint256 _prevCourse, uint256 _nextCourse) {
		founder = msg.sender;

		prevTokenAddress = _prevTokenAddress;
		nextTokenAddress = _nextTokenAddress;

		changeCourse(_prevCourse, _nextCourse);
	}
}
