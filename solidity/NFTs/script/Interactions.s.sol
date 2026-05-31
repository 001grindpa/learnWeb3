// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployBasicNFT} from "./DeployBasicNFT.s.sol";
import {DeployMoodNFT} from "./DeployMoodNFT.s.sol";
import {MoodNFT} from "../src/MoodNFT.sol";
import {BasicNFT} from "../src/BasicNFT.sol";
import {Script} from "../lib/forge-std/src/Script.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract MintBasicNFT is Script {
    address public mostrecentlyDeployed;
    string public constant URI = "ipfs://QmawSrPbMJ8ptqxAvLU9Yg6mZx97Akj9p4V2VRwyjLbSfr";

    function mintNFT(address mostRecentDeployment) public {
        vm.startBroadcast();
        BasicNFT(mostRecentDeployment).mintNft(URI);
        vm.stopBroadcast();
    }

    function run() external {
        mostrecentlyDeployed = DevOpsTools.get_most_recent_deployment("BasicNFT", block.chainid);

        mintNFT(mostrecentlyDeployed);
    }
}

contract MintMoodNFT is Script {
    address public mostRecentlyDeployed;

    function run() external {
        mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MoodNFT", block.chainid);
        
        vm.startBroadcast();
        MoodNFT(mostRecentlyDeployed).mintNFT();
        vm.stopBroadcast();
    }
}