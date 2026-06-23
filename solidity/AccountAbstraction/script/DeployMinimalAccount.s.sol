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
        // minimal.transferOwnership(msg.sender); // this line of code is not neccessary because 
        // the owner would always be the current msg.sender even when we 
        // insert a third party wallet inside the startBroadcast parenthesis in an attempt to
        // make the third part wallet owner during this deployment 
        // console.log(minimal.owner());
        vm.stopBroadcast();

        return (minimal, helperConfig);
    }
}