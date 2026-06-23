// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {MinimalAccount} from "../../src/MinimalAccount.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployMinimalAccount} from "../../script/DeployMinimalAccount.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract TestMinimalAccount is Test {
    MinimalAccount minimalAccount;
    HelperConfig helperConfig;
    DeployMinimalAccount deployer;
    address entryPoint;
    address public user = makeAddr("user");
    ERC20Mock usdc;
    uint256 TEST_AMOUNT = 5e18; // 5 tokens

    function setUp() external {
        deployer = new DeployMinimalAccount();
        (minimalAccount, helperConfig) = deployer.run();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entryPoint = config.entryPoint;

        vm.deal(user, 5e10);
        // deploy erc20 token mock
        usdc = new ERC20Mock();
    }

    /**
    * @dev This test function also calculates gas used(which is unneccesary)
    * @notice This test function checks if the smart wallet deployer can call
    * the execute function in the smart wallet
     */
     function testOwnerCanExecuteCommands() public {
        // check mock erc20 token balance in minimalAccount smart wallet before minting tokens to it
        console.log(usdc.balanceOf(address(minimalAccount)));

        address dest = address(usdc);
        // since we're not sending eth to the mock erc20 contract
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), TEST_AMOUNT);

        vm.txGasPrice(1 gwei);
        console.log("Gas price: ", tx.gasprice);
        uint256 gasStart = gasleft();
        vm.prank(minimalAccount.owner());
        minimalAccount.execute(dest, value, functionData);
        uint256 gasUsed = gasStart - gasleft();
        console.log("Gas used: ", gasUsed);
        uint256 gasCost = gasUsed * tx.gasprice;
        console.log("Gas cost: ", gasCost);

        // check mock erc20 token balance in minimalAccount smart wallet afterwards
        // console.log(usdc.balanceOf(address(minimalAccount)));
        assert(usdc.balanceOf(address(minimalAccount)) == TEST_AMOUNT);
     }
    
    /**
    * @notice This function tests if minimal account reverts when an address
    * that is not either the Entry point contract or EOA address tries to call
    * it's execute function
     */
     function testNonOwnerCanNotRunExecuteFunction() public {
        address dest = address(usdc);
        // since we're not sending eth to the mock erc20 contract
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), TEST_AMOUNT);

        vm.expectRevert(abi.encodeWithSelector(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector, address(user)));
        vm.prank(user);
        minimalAccount.execute(dest, value, functionData);
     }
}