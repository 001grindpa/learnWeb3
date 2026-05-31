// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDecentralisedStableCoin} from "../../script/DeployDecentralisedStableCoin.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralisedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

/**
 * @dev This contract uses the handler method, which allows
 * the fuzzer to make logical calls
 */
contract InvariantTest is StdInvariant, Test {
    DeployDecentralisedStableCoin deployer;
    DSCEngine engine;
    DecentralisedStableCoin dsc;
    HelperConfig config;
    address weth;
    address wbtc;
    Handler handler;

    function setUp() external {
        deployer = new DeployDecentralisedStableCoin();
        (dsc, engine, config) = deployer.run();
        (,, weth, wbtc,) = config.activeNetworkConfig();

        // // tell the stateful fuzzer the target contract to call from
        // targetContract(address(engine));
        handler = new Handler(engine, dsc);
        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
        // get the value of the collateral in the protocol
        // compare it to all the debt (dsc)
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(engine));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(engine));

        uint256 wethValue = engine.getCollateralAmountInUSD(weth, totalWethDeposited);
        uint256 wbtcValue = engine.getCollateralAmountInUSD(wbtc, totalWbtcDeposited);

        // display the current contract state after the fuzzer is done tampering with it
        console.log("Total DSC supply: ", totalSupply);
        console.log("Total weth deposited: ", totalWethDeposited);
        console.log("Total wbtc deposited: ", totalWbtcDeposited);
        console.log("Current Eth Price: ", engine.getTokenPrice(weth));

        assert(wethValue + wbtcValue >= totalSupply);
    }

    function invariant_gettersShouldNeverRevert() public view {
        engine.getAccountCollateralValue(msg.sender);
        engine.getAccountInformation(msg.sender);
        engine.getCollateralTokens();
    }
}
