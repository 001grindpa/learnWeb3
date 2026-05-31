//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {SimpleToken} from "../src/SimpleToken.sol";
import {Script} from "../lib/forge-std/src/Script.sol";

contract DeploySimpleToken is Script {
    SimpleToken simpleToken;
    uint256 public constant INITIAL_SUPPLY = 5000 ether;

    function run() external returns (SimpleToken) {
        return deployToken();
    }

    function deployToken() public returns (SimpleToken) {
        vm.startBroadcast();
        simpleToken = new SimpleToken(INITIAL_SUPPLY);
        vm.stopBroadcast();

        return simpleToken;
    }
}
