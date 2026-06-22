// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MinimalAccount} from "../src/MinimalAccount.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployMinimalAccount is Script {
    function run() external returns (MinimalAccount, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        address entryPoint = config.entryPoint;

        
        vm.startBroadcast();
        MinimalAccount minimal = new MinimalAccount(entryPoint);
        // during testing, ownership is trasfered to the test contract,
        // so that we can use it to test the implemented execute() function 
        minimal.transferOwnership(msg.sender);
        vm.stopBroadcast();

        return (minimal, helperConfig);
    }
}