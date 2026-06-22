// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {MinimalAccount} from "../../src/MinimalAccount.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployMinimalAccount} from "../../script/DeployMinimalAccount.s.sol";

contract TestMinimalAccount is Test {
    MinimalAccount minimalAccount;
    HelperConfig helperConfig;
    DeployMinimalAccount deployer;
    address entryPoint;
    address public user = makeAddr("user");

    function setUp() external {
        deployer = new DeployMinimalAccount();
        (minimalAccount, helperConfig) = deployer.run();
        entryPoint = HelperConfig.getConfig();

        vm.deal(user, 5e10);
    }
}