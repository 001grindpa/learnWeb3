// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// ───────────────────────────────────────────────
// Interface (you can also import from npm if using Hardhat/Foundry)
// ───────────────────────────────────────────────
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

/// @title ETH/USD Price Feed Consumer – Sepolia Testnet Version
/// @notice Reads real-time-ish ETH/USD price on Sepolia (no API key needed)
/// @dev Deploy & test on Sepolia testnet only
contract ETHUSDPriceConsumerSepolia {

    AggregatorV3Interface internal priceFeed;

    // Sepolia ETH / USD Data Feed (official Chainlink address – 8 decimals)
    // https://data.chain.link/feeds/ethereum/testnet/sepolia/eth-usd
    address constant SEPOLIA_ETH_USD = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

    constructor() {
        priceFeed = AggregatorV3Interface(SEPOLIA_ETH_USD);
    }

    // ───────────────────────────────────────────────
    // Core price functions
    // ───────────────────────────────────────────────

    /// @notice Latest ETH price in USD (as returned by Chainlink – usually ×10⁸)
    function getLatestPrice() public view returns (int256) {
        (, int256 price,,,) = priceFeed.latestRoundData();
        return price;
    }

    /// @notice Latest ETH price scaled to 18 decimals (easier for ETH calculations)
    /// @dev Multiplies the 8-decimal price by 10¹⁰
    function getLatestPrice18Decimals() public view returns (uint256) {
        (, int256 price,,,) = priceFeed.latestRoundData();
        // Safe cast – price feed should never return negative on healthy network
        return uint256(price) * 10**10;
    }

    /// @notice Full latest round data (useful for debugging)
    function getLatestRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return priceFeed.latestRoundData();
    }

    // ───────────────────────────────────────────────
    // Helpers – good for verification
    // ───────────────────────────────────────────────

    function decimals() external view returns (uint8) {
        return priceFeed.decimals();        // should return 8
    }

    function description() external view returns (string memory) {
        return priceFeed.description();     // "ETH / USD"
    }

    function version() external view returns (uint256) {
        return priceFeed.version();
    }
}