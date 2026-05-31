// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.18;
// import { Test } from "forge-std/Test.sol";
// import { StdInvariant } from "forge-std/StdInvariant.sol";
// import { DeployDecentralisedStableCoin } from "../../script/DeployDecentralisedStableCoin.s.sol";
// import { HelperConfig } from "../../script/HelperConfig.s.sol";
// import { DSCEngine } from "../../src/DSCEngine.sol";
// import { DecentralisedStableCoin } from "../../src/DecentralizedStableCoin.sol";
// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract InvariantTest is StdInvariant, Test {
//     DeployDecentralisedStableCoin deployer;
//     DSCEngine engine;
//     DecentralisedStableCoin dsc;
//     HelperConfig config;
//     address weth;
//     address wbtc;

//     function setUp() external {
//         deployer = new DeployDecentralisedStableCoin();
//         (dsc, engine, config) = deployer.run();
//         (,, weth, wbtc,) = config.activeNetworkConfig();

//         // tell the stateful fuzzer the target contract to call from
//         targetContract(address(engine));
//     }

//     function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
//         // get the value of the collateral in the protocol
//         // compare it to all the debt (dsc)
//         uint256 totalSupply = dsc.totalSupply();
//         uint256 totalWethDeposited = IERC20(weth).balanceOf(address(engine));
//         uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(engine));

//         uint256 wethValue = engine.getCollateralAmountInUSD(weth, totalWethDeposited);
//         uint256 wbtcValue = engine.getCollateralAmountInUSD(wbtc, totalWbtcDeposited);

//         assert(wethValue + wbtcValue > totalSupply);
//     }
// }
