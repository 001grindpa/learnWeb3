// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {SimpleToken} from "../../src/SimpleToken.sol";
import {DeploySimpleToken} from "../../script/DeploySimpleToken.s.sol";

contract TestSimpleToken is Test {
    // create variables for simpletoken and deployer datatypes(contracts)
    SimpleToken public simpleToken;
    DeploySimpleToken public deployer;

    // create test users we'll use interacting
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    // funding amount
    uint256 public STARTING_BAL = 1500 ether;

    function setUp() public {
        deployer = new DeploySimpleToken();
        simpleToken = deployer.run();

        /* Because deployer deployed simpleToken contract, it holds the supply of tokens in it's balance.
        From this balance we can transfer some token to bob, then have bob send some to alise
        */
        vm.prank(msg.sender);
        simpleToken.transfer(bob, STARTING_BAL);
    }

    function testBobBalance() public view {
        assertEq(STARTING_BAL, simpleToken.balanceOf(bob));
    }

    function testAllowancesWork() public {
        uint256 initialBobBalance = simpleToken.balanceOf(bob);
        uint256 initialAllowance = 1000;
        uint256 transferAmount = 500;

        // bob will now allow alice to spend up to "1000" tokens from his balance
        vm.prank(bob);
        simpleToken.approve(alice, initialAllowance);

        // to sepnd the allowed amount alise will use transferFrom global
        vm.prank(alice);
        simpleToken.transferFrom(bob, alice, transferAmount);

        // test equality
        assertEq(transferAmount, simpleToken.balanceOf(alice)); // check if alice pulled the right amount from bob
        assertEq(simpleToken.balanceOf(bob), (initialBobBalance - transferAmount)); // check if exactly 500 was pulled from bob
    }

    // use chatGPT for writing more test
}