// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Script} from "../lib/forge-std/src/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    error HelperConfig__ChainIsNotAvailable();

    // == MAGIC NUMBERS == //
    uint8 public PRICE_DECIMAL = 8;
    int256 public ETH_USD_PRICE = 2000e8;
    int256 public BTC_USD_PRICE = 1000e8;
    uint256 public DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    // == CUSTOM TYPES == //
    struct NetworkConfig {
        address wethUsdPriceFeed;
        address wbtcUsdPriceFeed;
        address weth;
        address wbtc;
        uint256 deployerKey;
    }

    // == STATE VARIABLE == //
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaNetworkConfig();
        } else if (block.chainid == 31337) {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__ChainIsNotAvailable();
        }
    }

    // == FUNCTIONS == //
    function getSepoliaNetworkConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            wethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wbtcUsdPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            weth: 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14,
            wbtc: 0xDfBBF048075D9db3c34aB34a0843bC16De8c3B3D, // 0xdfbbf048075d9db3c34ab34a0843bc16de8c3b3d
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.wethUsdPriceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockV3AggregatorEth = new MockV3Aggregator(PRICE_DECIMAL, ETH_USD_PRICE);
        MockV3Aggregator mockV3AggregatorBtc = new MockV3Aggregator(PRICE_DECIMAL, BTC_USD_PRICE);

        ERC20Mock wEthMock = new ERC20Mock(); // "WETH", "WETH", msg.sender, 1000e8
        ERC20Mock wBtcMock = new ERC20Mock(); // "WBTC", "WETH", msg.sender, 1000e8
        vm.stopBroadcast();

        return NetworkConfig({
            wethUsdPriceFeed: address(mockV3AggregatorEth),
            wbtcUsdPriceFeed: address(mockV3AggregatorBtc),
            weth: address(wEthMock),
            wbtc: address(wBtcMock),
            deployerKey: DEFAULT_ANVIL_KEY
        });
    }
}
