// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title OracleLib
 * @author 0xGrindpa
 * @notice This library is used to check the Chainlink Oracle for stable data.
 * If a price is stable, the function wil revert, and render the DSCEngine unusable - this is by design
 * We want the DSCEngine to freeze if prices become stale.
 *
 * So if the Chainlink network explodes and you have a lot of money locked in the protocol
 *
 */
library OracleLib {
    error OracleLib__StalePrice();
    // hardcode the priceFeed heartbeat (time it takes to update token price)
    uint256 private constant TIMEOUT = 3 hours; // 1 hours = 60 * 60 = 3600 sec

    function stalePriceCheckLatestRoundData(AggregatorV3Interface pricefeed) 
    public 
    view 
    returns (uint80, int256, uint256, uint256, uint80) {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            pricefeed.latestRoundData();

        // updatedAt contains the timestamp the last pricefeed was given
        uint256 secondsSinceLastPriceFeed = block.timestamp - updatedAt;

        // time since the previous pricefeed data was given is not supposed
        // to be more than the required time to provide new data
        // else the priceFeed aggregator might be broken(stale)
        if (secondsSinceLastPriceFeed > TIMEOUT) revert OracleLib__StalePrice();
        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }
}
