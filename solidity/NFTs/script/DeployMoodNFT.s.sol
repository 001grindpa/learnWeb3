// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {MoodNFT} from "../src/MoodNFT.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {console} from "../lib/forge-std/src/Test.sol";

contract DeployMoodNFT is Script {
    function run() external returns (MoodNFT) {
        string memory sadSvgCode = vm.readFile("./images/sadFace.svg");
        string memory happySvgCode = vm.readFile("./images/smilyFace.svg");

        vm.startBroadcast();
        MoodNFT moodNft = new MoodNFT(svgCodeToSvgURI(sadSvgCode), svgCodeToSvgURI(happySvgCode));
        vm.stopBroadcast();
        return moodNft;
    }

    function svgCodeToSvgURI(string memory svg) public pure returns (string memory) {
        // create the svgURI prefix
        string memory baseURL = "data:image/svg+xml;base64,";
        // create a base64 string of the incoming svg code
        string memory svgToBase64 = Base64.encode(
            bytes(
                string(abi.encodePacked(svg))
            )
        );
        // form the svgURI
        string memory svgURI = string.concat("",baseURL,"",svgToBase64,"");
        // string memory svgURI = string(abi.encodePacked(baseURL, svgToBase64));

        return svgURI;
    }

    function getBase64String(string memory svg) public pure returns (string memory) {
        string memory svgToBase64 = Base64.encode(
            bytes(
                string(abi.encodePacked(svg))
            )
        );
        return svgToBase64;
    }

    // cast send 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 "flipMood(uint256)" 1 
    // --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 
    // --rpc-url http:127.0.0.1:8545
    // command to run flipMood() with cast in terminal on anvil
}