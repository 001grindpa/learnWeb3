// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {Random} from "../../src/Test.sol";
import {DeployRandom} from "../../script/TestTest.s.sol";
import {Test, console} from "../../lib/forge-std/src/Test.sol";

contract TestTest is Test {
    Random random;
    DeployRandom deployer;

    function setUp() public {
        deployer = new DeployRandom();
        random = deployer.run();
    }

    function testSayHelloReturnsKelvin() view public {
        string memory name = "Kelly";
        console.log(random.sayHello(name));
        assertEq(random.sayHello(name), "Hello my name is Kelly, nice to meet you");
    }
}