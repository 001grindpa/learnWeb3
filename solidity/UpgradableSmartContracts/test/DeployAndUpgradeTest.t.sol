// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DeployBox} from "../script/DeployBox.s.sol";
import {UpgradeBox} from "../script/UpgradeBox.s.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {BoxV1} from "../src/BoxV1.sol";
import {BoxV2} from "../src/BoxV2.sol";
import {Test, console} from "forge-std/Test.sol";

contract TestUpgradeableContract is Test {
    DeployBox deployer;
    UpgradeBox upgrader;
    address proxy;
    address public user = makeAddr("user");

    function setUp() external {
        // instanciate deployer and upgrader
        deployer = new DeployBox();
        upgrader = new UpgradeBox();
        
        proxy = deployer.run(); // proxy points to BoxV1 by default
    }

    function testLogicVersion() public {
        uint256 expectedVersion = 1;
        uint256 version = BoxV1(proxy).version();

        console.log("Logic contract version: ", version);
        assert(version == expectedVersion);
    }

    function testLogicVersionAfterUpgrade() public {
        uint256 expectedVersion = 2;
        // instanciate updated implementation contract
        BoxV2 newBox = new BoxV2();
        // upgrade to new logic contract
        upgrader.upgradeBox(proxy, address(newBox));

        // test new version
        uint256 version = BoxV2(proxy).version();
        console.log("Logic contract version: ", version);
        assertEq(version, expectedVersion);
    }

    function testSetNumberAndGetItInV1() public {
        vm.startPrank(user);
        BoxV1(proxy).setNumber(11);
        // get assigned number
        uint256 number = BoxV1(proxy).getNumber();
        vm.stopPrank();

        console.log("Number: ", number);
        assert(number == 11);
    }

    function testSetNumberAndGetItInV2() public {
        uint256 numberArg = 11;
        BoxV2 newLogic = new BoxV2();

        upgrader.upgradeBox(proxy, address(newLogic));
        // set and get number
        vm.startPrank(user);
        BoxV2(proxy).setNumber(numberArg);
        uint256 number = BoxV2(proxy).getNumber();
        vm.stopPrank();
        uint256 expectedValue = numberArg + 2;

        console.log("New Number: ", number);
        assert(number == expectedValue);
    }
}