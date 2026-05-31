// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Random} from "../src/Test.sol";
import {Script} from "../lib/forge-std/src/Script.sol";

contract DeployRandom is Script {
    function run() external returns (Random) {
        vm.startBroadcast();
        Random random = new Random();
        vm.stopBroadcast();

        return random;
    }
}