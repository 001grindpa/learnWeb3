// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralisedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract Handler is Test {
    DecentralisedStableCoin dsc;
    DSCEngine engine;
    address weth;
    address wbtc;
    uint256 MAX_DEPOSIT_SIZE = type(uint96).max; // max value uint96 can hold
    uint256 MAX_MINT_SIZE = type(uint8).max; // max amount an 8 bit unsigned integer variable can hold
    enum STATE {
        deposit,
        no_deposit
    }
    STATE state = STATE.no_deposit;
    MockV3Aggregator public ethUsdPriceFeed;

    constructor(DSCEngine _engine, DecentralisedStableCoin _dsc) {
        engine = _engine;
        dsc = _dsc;

        // get collateral tokens from engine
        address[] memory collateralTokens = engine.getCollateralTokens();
        weth = collateralTokens[0];
        wbtc = collateralTokens[1];

        // get weth price feed
        ethUsdPriceFeed = MockV3Aggregator(engine.getCollateralTokenPriceFeed(address(weth)));
    }

    // redeem collateral
    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        /* collateralSeed is supposed to be an address arg but because
        the fuzzer will insert a random address that's not valid
        we use an uint256 instead, so that when it inserts a random uint256,
        if it's an even number, we use a _getCollateralWithSeed() private function
        to get weth address, else if it's an odd number, we get wbtc.
        either way, the address we're getting from the getCollateralFromSeed()
        function will be within the bounds of what's valid */
        address collateralToken = _getCollateralWithSeed(collateralSeed);
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);

        // mint some weth token to msg.sender (the invariantsTest contract address fuzzing this function)
        vm.startPrank(msg.sender);
        ERC20Mock(collateralToken).mint(msg.sender, amountCollateral + 50);
        ERC20Mock(collateralToken).approve(address(engine), amountCollateral);

        engine.depositCollateral(collateralToken, amountCollateral);
        vm.stopPrank();
    }

    // this function mints dsc after depositing collateral
    function mintDsc(uint256 amountToMint, uint256 collateralSeed) public {
        // check if deposit amount is low or 0 then call deposit
        // before executing mint
        address collateralCA = _getCollateralWithSeed(collateralSeed);
        uint256 totalCollateralDeposit = engine.getUserCurrentCollateralAmount(collateralCA, msg.sender);
        amountToMint = bound(amountToMint, 1, MAX_MINT_SIZE);
        uint256 threeXamountToMint = (amountToMint * 150) / 100; // amountToMint * 1.5

        if (threeXamountToMint >= totalCollateralDeposit || totalCollateralDeposit == 0) {
            depositCollateral(collateralSeed, threeXamountToMint);
        }

        // mint token if all conditions are met
        vm.prank(msg.sender);
        engine.mintDsc(amountToMint);
    }

    function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        // check if contract already has deposit before allowing withdraw to go through
        // when the fuzzer calls it
        if (
            state == STATE(1) /* no deposit */
        ) {
            depositCollateral(collateralSeed, amountCollateral);
            state = STATE(0);
        }
        address collateralToken = _getCollateralWithSeed(collateralSeed);
        // uint256 amountCollateral = bound(amountCollateral, 1, type(uint256).max); // 
        // some txns will revert if withdrwal balance limit
        // is extended higher than the limit of deposit amount, this causes the condition 
        // in the require() block below to fail for some txn
        uint256 amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        uint256 maxCollateralAmount = engine.getUserCurrentCollateralAmount(collateralToken, msg.sender);
        require(amountCollateral <= maxCollateralAmount, "withrawal amount is greater than balance");
        engine.redeemCollateral(collateralToken, amountCollateral);
        vm.stopPrank();
        state = STATE.no_deposit; // STATE(1)
    }

    /**
     * @dev this function reassigns a random eth price for each run
     */
    function updateCollateralPrice(uint96 newPrice) public {
        // if price of eth crashes after minting dsc (if fuzzer passes a low eth price value here)
        // the system should auto flag for liquidation
        // almost immediately
        int256 newPriceInt = int256(uint256(newPrice));
        // MockV3Aggregator(engine.getCollateralTokenPriceFeed(address(weth))).updateAnswer(newPriceInt);
        ethUsdPriceFeed.updateAnswer(newPriceInt);
    }

    // == PRIVATE & INTERNAL FUNCTIONS == //
    // the invariant fuzzer from invariantTest script can't call private functions (obviously) from
    // this contract
    function _getCollateralWithSeed(uint256 collateralSeed) private view returns (address) {
        if (collateralSeed % 2 == 0) {
            return weth;
        } else {
            return wbtc;
        }
    }
}
