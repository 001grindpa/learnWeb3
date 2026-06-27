// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {EntryPoint} from "../lib/account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
    // === ERRORS === //
    error HelperConfig__NonImplementedChain(uint256 chainId);

    // === CUSTOM TYPES === //
    struct NetworkConfig {
        address entryPoint;
        address account;
    }
    // === STATE VARIABLES == //
    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant ARB_MAINNET_CHAIN_ID = 42161;
    mapping(uint256 chainId => NetworkConfig configs) public chainIdToConfig;
    NetworkConfig public localNetworkConfig;

    constructor() {
        chainIdToConfig[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
        chainIdToConfig[ARB_MAINNET_CHAIN_ID] = getArbitriumConfig();
    }

    // === PUBLIC/EXTERNAL FUNCTIONS === //
    function getEthSepoliaConfig() public view returns (NetworkConfig memory) {
        NetworkConfig memory config = NetworkConfig({
            entryPoint: 0x0576a174D229E3cFA37253523E645A78A0C91B57, // general Entry point ca for sepolia
            account: msg.sender
        });
        return config;
    }

    function getArbitriumConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory config = NetworkConfig({
            entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032,
            account: 0x8282B51f90DE07F1279cA36f0f559C5D7733BEd3
        });
        return config;
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        // if (localNetworkConfig.entryPoint != address(0)) {
        //     return localNetworkConfig;
        // } else {
        //     // account-abstraction lib has a mock entry point contract for anvil
        //     vm.startBroadcast();
        //     EntryPoint entryPoint = new EntryPoint();
        //     vm.stopBroadcast();

        //     localNetworkConfig = NetworkConfig({
        //         entryPoint: address(entryPoint),
        //         account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 // anvil account 1
        //     });
        // }
        // return localNetworkConfig;
    }

    // === GETTER === //
    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainId == ETH_SEPOLIA_CHAIN_ID) {
            return chainIdToConfig[ETH_SEPOLIA_CHAIN_ID];
        } else if (chainId == ARB_MAINNET_CHAIN_ID) {
            return chainIdToConfig[ARB_MAINNET_CHAIN_ID];
        } else if (chainId == 31337) {
            return getAnvilConfig();
        } else {
            revert HelperConfig__NonImplementedChain(block.chainid);
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }
}
