// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract Fund {
    uint256 public timesFunded;

    uint256 public USDPrice = 5e18;

    function getPrice() public view returns(uint256) {
        // address 0x694AA1769357215DE4FAC081bf1f309aDC325306
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        // Price of Eth in USD
        // 1850.00000000
        return uint256(answer * 1e10);
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethPriceInUSD = (ethAmount * ethPrice)/1e18;
        return ethPriceInUSD;
    }

    function add_fund() public payable {
        timesFunded += 1;
        require(getConversionRate(msg.value) >= USDPrice, "minimum funding is 1eth, please try again.");
    }
    
    function getVersion() public view returns(uint256) {
        return AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version();
    }
}