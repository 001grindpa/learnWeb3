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
    mapping(uint256 chainId => NetworkConfig configs) public chainIdToConfig;
    NetworkConfig public localNetworkConfig;

    constructor() {
        chainIdToConfig[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
    }

    // === PUBLIC/EXTERNAL FUNCTIONS === //
    function getEthSepoliaConfig() public view returns (NetworkConfig memory) {
        NetworkConfig memory config = NetworkConfig({
            entryPoint: 0x0576a174D229E3cFA37253523E645A78A0C91B57, // general Entry point ca for sepolia
            account: msg.sender
        });
        return config;
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.entryPoint != address(0)) {
            return localNetworkConfig;
        } else {
            // account-abstraction lib has a mock entry point contract for anvil
            vm.startBroadcast();
            EntryPoint entryPoint = new EntryPoint();
            vm.stopBroadcast();

            localNetworkConfig = NetworkConfig({
                entryPoint: address(entryPoint),
                account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 // anvil account 1
            });
        }
        return localNetworkConfig;
    }

    // === GETTER === //
    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainId == ETH_SEPOLIA_CHAIN_ID) {
            return chainIdToConfig[ETH_SEPOLIA_CHAIN_ID];
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
