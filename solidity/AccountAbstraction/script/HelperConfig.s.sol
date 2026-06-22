// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    // === ERRORS === //
    error HelperConfig__NonImplementedChain(uint256 chainId);

    // === CUSTOM TYPES === //
    struct NetworkConfig {
        address entryPoint;
    }
    // === STATE VARIABLES == //
    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    mapping(uint256 chainId => NetworkConfig configs) public chainIdToConfig;
    NetworkConfig public localNetworkConfig;

    constructor() {
        chainIdToConfig[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
    }

    // === PUBLIC/EXTERNAL FUNCTIONS === //
    function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory config = NetworkConfig({
            entryPoint: 0x0576a174D229E3cFA37253523E645A78A0C91B57 // default Entry point ca for sepolia
        });
        return config;
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.entryPoint != address(0)) {
            return localNetworkConfig;
        } else {


            localNetworkConfig = NetworkConfig({
                entryPoint: address(uint160(5))
            });
        }
    }

    // === GETTER === //
    function getConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
        if (chainId == ETH_SEPOLIA_CHAIN_ID) {
            return chainIdToConfig[ETH_SEPOLIA_CHAIN_ID];
        } else if (chainId == 31337) {
            return localNetworkConfig;
        } else {
            revert HelperConfig__NonImplementedChain(block.chainid);
        }
    }

    function getConfig() public view returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }
}