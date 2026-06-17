// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {BoxV1} from "../src/BoxV1.sol";
import {BoxV2} from "../src/BoxV2.sol";
import {DevOpsTools} from "devops/src/DevOpsTools.sol";
// import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeBox is Script {
    function upgradeBox(address mostRecentDeployment, address newLogic) public returns (address) {
        // typecast the proxy contract as a logic contract type
        // so that you can use the 'upgradeToAndCall' function on it directly
        // to change the implementation contract it points to
        BoxV1(mostRecentDeployment).upgradeToAndCall(newLogic, "");
        return address(mostRecentDeployment);
    }

    function run() external returns(address) {
        BoxV2 newBox;
        // the fetched deployed address is the proxy address obviously
        // since the v1 logic contract was instanciated and passed as the
        // proxy constructor argument during it's deployment 
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment("ERC1967Proxy", block.chainid);

        vm.startBroadcast();
        newBox = new BoxV2();
        upgradeBox(mostRecentDeployment, address(newBox));
        vm.stopBroadcast();

        return address(mostRecentDeployment);
    }
}
