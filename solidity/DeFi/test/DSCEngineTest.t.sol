// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {DecentralisedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DeployDecentralisedStableCoin} from "../script/DeployDecentralisedStableCoin.s.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract DSCEngineTest is Test {
    DecentralisedStableCoin public dsc;
    DSCEngine public engine;
    HelperConfig public config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address wbtc;
    address weth;
    address public USER1 = makeAddr("user1");
    uint256 public COLLATERAL_VALUE = 200;

    function setUp() external {
        // fund test user
        vm.deal(USER1, 10 ether);

        DeployDecentralisedStableCoin deployer = new DeployDecentralisedStableCoin();
        (dsc, engine, config) = deployer.run();
        // get eth data(tokenContract ca and priceFeed ca) from config
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc,) = config.activeNetworkConfig();

        // mint some erc20 token to user for collateral
        ERC20Mock(weth).mint(USER1, 10 ether);
    }

    // == CONSTRUCTOR TEST == //
    address[] public priceFeedCAs;
    address[] public tokenAddressCAs;

    function testIfTokenCaArrayAndPriceFeedCaArrayAreEqualInLength() public {
        priceFeedCAs.push(btcUsdPriceFeed);
        tokenAddressCAs = [wbtc, weth];

        vm.expectRevert(
            abi.encodeWithSelector(
                DSCEngine.DSCEngine__AddressesAndPriceFeedsArrayMustBeEqualInLength.selector,
                tokenAddressCAs,
                priceFeedCAs
            )
        );
        new DSCEngine(tokenAddressCAs, priceFeedCAs, address(dsc));
    }

    // == PRICE TESTS == //

    function testGetUsdValue() public view usesAnvilHardCodedData {
        uint256 ethAmount = 15e18;
        // 15e18 * 2000 = 30,000e18
        uint256 expectedUsdValue = 30000e18;
        uint256 actualUsdValue = engine.getCollateralAmountInUSD(weth, ethAmount);
        assertEq(expectedUsdValue, actualUsdValue);
        console.log(actualUsdValue);
    }

    function testGetEquivalenceInCollateral() public usesAnvilHardCodedData {
        vm.prank(USER1);
        // 'paidOffDebtInCollateral' is the collateral (weth, wbtc) equivalence in USD
        uint256 paidOffDebtInCollateral = engine.getRepaidEquivalenceInCollateral(weth, 100e18);
        uint256 expectedValue = 0.05 ether; // because 100/2000 = 0.05 (ether == 1e18)
        console.log(paidOffDebtInCollateral);

        assertEq(expectedValue, paidOffDebtInCollateral);
    }

    /**
     * @dev Run this test with level 3 verbosity (use flag -vvv)
     */
    function testGetTokenPrice() public view {
        int256 tokenPrice = engine.getTokenPrice(weth);
        console.log("Token price: $%s", tokenPrice / 1e8);
    }

    /**
     * @dev Run this test with level 3 verbosity (use flag -vvv)
     */
    function testGetTokenPriceOnPublicMap() public {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(engine.sTokenToPriceFeedMap(wbtc));
        (, int256 priceInUsd,,,) = priceFeed.latestRoundData();
        console.log("Token price: $%s", priceInUsd/1e8);
    }

    // == DEPOSIT COLLATERAL TEST == //

    function testRevertIfCollateralIsZero() public {
        vm.startPrank(USER1);
        ERC20Mock(weth).approve(address(engine), 4e18);

        // vm.expectRevert() takes 4 bytes custom error selectors
        /**
         * insert the expector error instance calldata in expectRevert();
         * this way the cheat code knows what specific error to expect
         */
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__NeedsMoreThanZero.selector, 0));
        engine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    // this function tests if the used token is a whitelisted collateral token
    function testIfTokenIsWhiteListedCollateral() public {
        ERC20Mock randToken = new ERC20Mock();
        randToken.mint(USER1, 5000);

        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__NotAllowedToken.selector, randToken));
        engine.depositCollateral(address(randToken), 2000);
        vm.stopPrank();
    }

    /**
     * This function gets debtor's account
     * info after collateral is deposited
     */
    function testCanDepositCollateralAndGetAccountInfo() public usesAnvilHardCodedData depositCollateral {
        // don't allow sepolia fork test
        // since we're comparing hardcoded anvil eth value here
        if (block.chainid == 11155111) {
            return;
        }
        uint256 expectedDscSize = 200;
        uint256 ethUsdValue = 2000;

        vm.prank(USER1);
        engine.mintDsc(expectedDscSize);

        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(USER1);
        // console.log(totalDscMinted, collateralValueInUsd);

        assertEq(totalDscMinted, expectedDscSize);
        assertEq(collateralValueInUsd, (COLLATERAL_VALUE * ethUsdValue));
    }

    function testCanRedeemCollateral() public usesAnvilHardCodedData depositCollateral {
        vm.prank(USER1);
        engine.redeemCollateral(address(weth), 50);

        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(USER1);
        console.log(totalDscMinted, collateralValueInUsd);
        vm.assertEq(collateralValueInUsd, (COLLATERAL_VALUE - 50) * 2000);
    }

    function testCanRedeemCollateralAndBurnDsc() public usesAnvilHardCodedData depositCollateral {
        vm.startPrank(USER1);
        engine.mintDsc(100);

        uint256 mintedDsc = engine.getDscMinted();

        console.log(mintedDsc);
        (uint256 initialTotalDscMinted, uint256 initialCollateralValueInUsd) = engine.getAccountInformation(USER1);

        // redeem collateral and burn dsc
        // give engine dsc approval to transfer user's dsc to engine during burning
        dsc.approve(address(engine), 1000);
        engine.redeemCollateralForDsc(address(weth), COLLATERAL_VALUE, 100);
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(USER1);
        vm.stopPrank();

        console.log(initialTotalDscMinted, initialCollateralValueInUsd);
        console.log(totalDscMinted, collateralValueInUsd);
    }

    // == TOKEN TESTS == //
    /**
     * @dev this function checks if user can burn (pay back)
     * their dsc directly without having to redeeem collateral first
     */
    function testBurnDscWithoutRedeemingCollateral() public usesAnvilHardCodedData depositCollateral {
        vm.startPrank(USER1);
        engine.mintDsc(200);
        uint256 initialTotalDscHoldings = engine.getDscMinted();
        console.log(initialTotalDscHoldings);

        dsc.approve(address(engine), 50);
        engine.burnDsc(50);
        uint256 currentTotalDscHoldings = engine.getDscMinted();
        vm.stopPrank();
        console.log(currentTotalDscHoldings);
        assertEq(currentTotalDscHoldings, initialTotalDscHoldings - 50);
    }

    // == MODIFIERS == //
    modifier depositCollateral() {
        vm.startPrank(USER1);
        ERC20Mock(weth).approve(address(engine), 1000);
        engine.depositCollateral(weth, COLLATERAL_VALUE);
        vm.stopPrank();
        _;
    }
    modifier usesAnvilHardCodedData() {
        // don't allow sepolia fork test
        // since we're comparing hardcoded anvil eth value here
        if (block.chainid == 11155111) {
            return;
        }
        _;
    }

    // function testAgeIsWithinRange(uint256 age) public {
    //     // restricts random fuzz numbers to a range
    //     age = bound(age, 1, 30);

    //     vm.prank(USER1);
    //     bool state = engine.checkWhichAgeBreaksLimit(age);

    //     assertEq(state, true);
    // }
}
