// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function get_eth_price() internal view returns(uint256) {
        AggregatorV3Interface ethInUSD = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int256 answer,,,) = ethInUSD.latestRoundData();
        return uint256(answer*1e10);
    }

    function get_conversion_rate(uint256 ethSize) internal view returns(uint256) {
        uint256 ethPriceInUSD = get_eth_price();
        uint256 ethSizeInUSD = (ethSize * ethPriceInUSD)/1e18;
        return ethSizeInUSD;
    }
}