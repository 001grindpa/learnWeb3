// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {MinimalAccount} from "../src/MinimalAccount.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployMinimalAccount is Script {
    function run() external returns (MinimalAccount, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        address entryPoint = config.entryPoint;

        vm.startBroadcast();
        MinimalAccount minimal = new MinimalAccount(entryPoint);
        // transfer ownership from default sender to account in config.account
        minimal.transferOwnership(config.account);
        vm.stopBroadcast();

        return (minimal, helperConfig);
    }
}
