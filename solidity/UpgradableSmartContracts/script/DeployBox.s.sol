// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {BoxV1} from "../src/BoxV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployBox is Script {
    function run() external returns (address) {
        address proxy = deployBox();
        return proxy;
    }

    function deployBox() public returns (address){
        BoxV1 boxV1;
        ERC1967Proxy proxy;

        vm.startBroadcast();
        // instanciate logic contract V1
        boxV1 = new BoxV1();
        // instanciating proxy contract directly (no child)
        // if there's any state varaiables you would like to assign value to,
        // in the just deployed implementation initializer pass it's hash
        // in the second position. Pass empty string if nothing
        // the implementation ca is passed as an address type not its contract type
        proxy = new ERC1967Proxy(address(boxV1), abi.encodeWithSignature("initialize()"));
        vm.stopBroadcast();
        // return proxy as address type too
        return address(proxy);
    }
}