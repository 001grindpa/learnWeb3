// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {DecentralisedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DeployDecentralisedStableCoin} from "../script/DeployDecentralisedStableCoin.s.sol";

contract TestDecentralisedStableCoin is Test {
    // // declare contract variables
    // DecentralisedStableCoin dsc;
    // DeployDecentralisedStableCoin deployer;
    // // declare user
    // address public USER = makeAddr("user");
    // function setUp() external {
    //     deployer = new DeployDecentralisedStableCoin();
    //     dsc = deployer.run();
    //     // send test token to user
    //     vm.deal(USER, 5 ether);
    // }
    // function testTokenMinting() public {
    //     vm.prank(msg.sender);
    //     dsc.mint(USER, 1000);
    //     assert(dsc.getBalance(USER) == 1000);
    // }
    // function testTokenBurning() public {}

    }
