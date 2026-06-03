// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {ChimChimToken} from "../src/ChimChimToken.sol";

contract DeployMerkleAirdrop is Script {
    function run() public returns (MerkleAirdrop, ChimChimToken) {
        MerkleAirdrop merkleAirdrop;
        ChimChimToken cct = new ChimChimToken();

        vm.startBroadcast();
        merkleAirdrop = new MerkleAirdrop(0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4, address(cct));
        vm.stopBroadcast();
        return (merkleAirdrop, cct);
    }
}
