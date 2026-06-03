// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console} from "../lib/forge-std/src/console.sol";
import {DecentralisedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {OracleLib} from "./libraries/OracleLib.sol";

/**
 * @title DSCEngine
 * @author 0xgrindpa
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg.
 * This stablecoin has the properties:
 * Relative/pegged
 * algorithmic stability
 * exogenous collateralisation
 *
 * it is similar to DAI if DAI had no governance, no fees and was only backed by WETH and WBTC.
 *
 * Our DSC System should always be "overcollateralized". At no point, should the value of all 
 * collateral <= the dollar backed value of all the DSC.
 *
 * @notice This contract is the core of the DSC System. It handles all the logic for mining and 
 * redeeming DSC, as well as depositing & withdrawing collateral.
 * @notice This contract is VERY loosely based on the MakerDAO DSS (DAI) system.
 */

contract DSCEngine is ReentrancyGuard {
    // === ERRORS === //
    error DSCEngine__NeedsMoreThanZero(uint256 amnt);
    error DSCEngine__AddressesAndPriceFeedsArrayMustBeEqualInLength(address[] tokenAddresses, address[] priceFeeds);
    error DSCEngine__NotAllowedToken(address token);
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__calculateHealthFactorOk();
    error DSCEngine__calculateHealthFactorNotImproved();

    // == SYNTACTIC SUGER == //
    using OracleLib for AggregatorV3Interface;

    // == STATE VARIABLES == //
    mapping(address tokenCA => address priceFeedCA) private sTokenToPriceFeedMap;
    mapping(address user => mapping(address token => uint256 amountOfToken)) private sUserToCollateralDepositedMap;
    mapping(address minter => uint256 dScSize) private sDSCMinted;
    DecentralisedStableCoin public immutable i_dSc;
    address[] private sCollateralTokens;
    uint256 private constant LIQUIDATION_THRESHOLD = 150; // 150% overcollateralized
    // // delete state varaible after
    // uint256 private sAgeLimit = 30;

    // === EVENTS === //
    event CollateralDeposited(address indexed sender, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(
        address indexed from, address indexed to, address indexed sender, address token, uint256 amount
    );

    // === MODIFIERS === //
    modifier moreThanZero(uint256 depositAmount) {
        if (depositAmount <= 0) {
            revert DSCEngine__NeedsMoreThanZero(depositAmount);
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (sTokenToPriceFeedMap[token] == address(0)) {
            revert DSCEngine__NotAllowedToken(token);
        }
        _;
    }

    // === FUNCTIONS === //
    /**
     * @notice This contract uses HelperConfig to since provide
     * the tokenCA, priceFeedsCA during deployment in the script contract
     */
    constructor(address[] memory tokenCAs, address[] memory priceFeeds, address dScAddress) {
        // sanity check if both arrays are of thesame length
        if (tokenCAs.length != priceFeeds.length) {
            revert DSCEngine__AddressesAndPriceFeedsArrayMustBeEqualInLength(tokenCAs, priceFeeds);
        }
        /**
         * populate the tokenToPriceFeed map with values
         * token address as property key and corresponding price feed as property value
         * all USD price feeds for this contract
         */
        for (uint256 i = 0; i < tokenCAs.length; i++) {
            sTokenToPriceFeedMap[tokenCAs[i]] = priceFeeds[i];
            sCollateralTokens.push(tokenCAs[i]);
        }
        i_dSc = DecentralisedStableCoin(dScAddress);
    }

    // === EXTERNAL & PUBLIC FUNCTIONS === //
    /**
     * @param tokenCollateralAddress The collateral token CA
     * @param amountCollateral The amount of incoming colateral
     * @param amountDscToMint The amount of Decentralised Stable Coin to mint
     * @notice This function allows a user to provide collateral and mint DSC at thesame time
     */
    function depositCollateralAndMintDsc(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDscToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountDscToMint);
    }

    /**
     * @notice This function follows the CEI pattern (Checks, Effects and Interaction)
     * @param tokenCollateralAddress - The address of the token to deposit as collateral
     * @param amountCollateral - The amount of collateral to deposit
     * @notice This function has a nonReentrant modifier inherited from ReentrantGuard Contract
     * that locks the function when it's processing data (the approcah consumes more gas).
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        // IERC20(tokenCollateralAddress).approve(address(this), amountCollateral);

        sUserToCollateralDepositedMap[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    /**
     * @param tokenCollateralAddress The collateral address to redeem
     * @param amountCollateral The ampunt of collateral to redeem
     * @param amountDscToBurn The amount of DSC token to burn
     * @notice This function burns DSC and redeems underlying collateral in one transaction
     */
    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToBurn)
        external
    {
        burnDsc(amountDscToBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
        // redeemCollateral() already checks health factor
    }

    // In order to redeem collateral;
    // 1. Health factor must be over 1 AFTER collateral pulled
    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        nonReentrant
    {
        _redeemCollateral(msg.sender, msg.sender, tokenCollateralAddress, amountCollateral);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) nonReentrant {
        sDSCMinted[msg.sender] += amountDscToMint;
        // if user tries to mint more than collateral value in DSC
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dSc.mint(msg.sender, amountDscToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDsc(uint256 amount) public {
        _burnDsc(amount, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender); // this line of code is not neccessary but just for total reassurance sake we'll add it
        // we don't need it because when DSC is burnt, the health factor actually increases since debt is reduced
    }

    // pay anyone to liquidate flagged positions
    /**
     * @param collateral The erc20 token address to liquidate from user
     * @param user Address of user who's health factor is broken
     * @param debtToCover The amount of DSC to burn (To improve user's health factor)
     * @notice - The protocol uses a 150% collateralisation ratio
     */
    function liquidate(address collateral, address user, uint256 debtToCover)
        external
        moreThanZero(debtToCover)
        nonReentrant
    {
        // check if user's health factor is broken (1.e if user is liquidatable)
        uint256 startingUserHealthFactor = _calculateHealthFactor(user);
        if (startingUserHealthFactor >= 1) {
            revert DSCEngine__calculateHealthFactorOk();
        }
        // repay their borrowed DSC and take extra
        // 10% of paid amount (liquidation fee) as incentive
        uint256 equivalenceOfDebtCovered = getRepaidEquivalenceInCollateral(collateral, debtToCover);
        // send 10% of equivalenceOfDebtCovered + equivalenceOfDebtCovered to liquidator
        uint256 liquidationFee = (equivalenceOfDebtCovered * 10) / 100; // 10/100 is 0.1 -> 10% of equivalenceOfDebtCovered
        uint256 totalCollateralToRetrieve = liquidationFee + equivalenceOfDebtCovered;

        _redeemCollateral(user, msg.sender, collateral, totalCollateralToRetrieve);

        // burn the repaid debt(DSC) provided by liquidator
        // to reset the user's history
        _burnDsc(debtToCover, user, msg.sender);

        // check if health factor was improved after liquidation
        uint256 endingHealthFactor = _calculateHealthFactor(user);
        if (endingHealthFactor <= startingUserHealthFactor) {
            revert DSCEngine__calculateHealthFactorNotImproved();
        }
        // if health factor was broken during liquidation
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function getHealthFactor() external view {}

    // === INTERNAL & PRIVATE FUNCTIONS === //

    /**
     * @notice This function allows DSCEngine to burn DSC repaid by a liquidator
     * @dev check if health factor is broken before calling this function
     */
    function _burnDsc(uint256 amountDscToBurn, address onBehalfOf, address dscFrom) private {
        sDSCMinted[onBehalfOf] -= amountDscToBurn;
        bool success = i_dSc.transferFrom(dscFrom, address(this), amountDscToBurn);
        // the line above can send the dsc to a 0 address to burn it
        // but since the ERC20 contract also has a burn function
        // we'll just send the token to DSCEngine contract dsc token CA(ERC20)
        // then call that burn function later to burn the dsc token
        // from the DSCEngine contract dsc balance
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        // now DSCEngine contract will call the official burn function from ERC20
        // on the dsc token it just recieved
        i_dSc.burn(amountDscToBurn);
        _revertIfHealthFactorIsBroken(msg.sender); // this line of code is not neccessary but just for total reassurance sake we'll add it
        // we don't need it because when DSC is burnt, the health factor actually increases since debt is reduced
    }

    /**
     * @notice This function allows the engine (this) to send a debtor's collateral
     * from their balance to a liquidator during liquidation
     * @param from Deptor's address
     * @param to Liquidator's address
     * @param tokenCollateralAddress The debtor's collateral token CA
     * @param amountCollateral The size of debt to be covered by liquidator
     */
    function _redeemCollateral(address from, address to, address tokenCollateralAddress, uint256 amountCollateral)
        private
    {
        sUserToCollateralDepositedMap[msg.sender][tokenCollateralAddress] -= amountCollateral;
        emit CollateralRedeemed(from, to, msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transfer(to, amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = sDSCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
        // manually return just to be more explicit
        return (totalDscMinted, collateralValueInUsd);
    }

    /**
     * @notice Retruns how close to liquidation a user is
     * if a user goes below 1, then they can get liquidated
     */
    function _calculateHealthFactor(address user) private view returns (uint256) {
        // total DSC minted
        // total collateral VALUE
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);

        // if a user has no debt, their health factor is maxed out
        if (totalDscMinted == 0) return type(uint256).max;

        // this simple math increases the minted DSC value by 150% i.e minted_dsc * 1.5
        uint256 healthChecker = totalDscMinted * (LIQUIDATION_THRESHOLD / 100); // collateral adjusted for threshold

        uint256 health = collateralValueInUsd / healthChecker; // checks if borrowed/collateral ratio is within range
        // if health is less than 1, the protocol flags for liquidation
        return health;
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _calculateHealthFactor(user);
        if (userHealthFactor <= 1) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    // === EXTERNAL & PUBLIC FUNCTIONS view === //

    /**
     * @notice This function allows the liquidator to get back an equivalent amount from borrower's
     * collteral after paying off their debt in USD
     * @param token The token address of the collateral (weth, wbtc)
     * @param usdAmountInWei The USD amount the liquidator is paying off for the borrower
     * (given in wei, instead of 2000 pass 2000e18 when calling this function)
     */
    function getRepaidEquivalenceInCollateral(address token, uint256 usdAmountInWei) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(sTokenToPriceFeedMap[token]);
        (, int256 priceInUsd,,,) = priceFeed.stalePriceCheckLatestRoundData();
        // recall that priceInUsd has extra 8 decimals

        // this line of code divides liquidator's paid amount
        // by the current price of 1 collateral token (weth, wbtc)
        // to get their paid amount equivalence in collateral value
        uint256 collateralEquivalence = (usdAmountInWei * 1e18 / uint256(priceInUsd * 1e10));

        // 'collateralEquivalence' is returned in wei beacuse it's an ether value
        return collateralEquivalence;
    }

    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUSD) {
        /*  loop through the state collateralTokens array, for each tokenCA, check the amount
            a user has deposited as collateral, then use a amountInUsd function to get user's
            collateral size in USD  */
        for (uint256 i = 0; i < sCollateralTokens.length; i++) {
            address tokenCA = sCollateralTokens[i];
            uint256 amount = sUserToCollateralDepositedMap[user][tokenCA];
            totalCollateralValueInUSD += getCollateralAmountInUSD(tokenCA, amount);
        }
        //  'totalCollateralValueInUSD' is declared in the 'Named Returns' above
        //  outside the loop scope, this is why the loop can continue to add and assign values to it
        //  without the value resetting
    }

    function getCollateralAmountInUSD(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(sTokenToPriceFeedMap[token]);
        // assuming the price of eth is 2000, 'usdPrice' will be 2000e8
        (, int256 usdPrice,,,) = priceFeed.stalePriceCheckLatestRoundData();

        // add extra 10 decimals to make 2000e18 and typecast 'usdPrice' to uint256
        uint256 _usdPrice = uint256(usdPrice * 1e10);

        uint256 amountInUsd = (amount * _usdPrice) / 1e18;
        // we already divided 1e18 out from 'amount'

        return amountInUsd;
        // value of amountInUsd has an extra 1e18 in it.
    }

    function getAccountInformation(address user)
        external
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        (totalDscMinted, collateralValueInUsd) = _getAccountInformation(user);
    }

    //  == GETER FUNCTIONS FOR STATE VARIABLES == //

    function getTokenPrice(address tokenCA) external view returns (int256 priceInUsd) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(sTokenToPriceFeedMap[tokenCA]);
        (, priceInUsd,,,) = priceFeed.stalePriceCheckLatestRoundData();
    }

    function getCollateralTokenPriceFeed(address tokenCA) external view returns (address) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(sTokenToPriceFeedMap[tokenCA]);
        return address(priceFeed);
    }

    function getDscMinted() external view returns (uint256) {
        return sDSCMinted[msg.sender];
    }

    function getCollateralTokens() public view returns (address[] memory) {
        return sCollateralTokens;
    }

    function getUserCurrentCollateralAmount(address collateralAddress, address user) public view returns (uint256) {
        return sUserToCollateralDepositedMap[user][collateralAddress];
    }

    // // delete this functions after
    // function checkWhichAgeBreaksLimit(uint256 age) public view returns (bool) {
    //     require(age <= sAgeLimit, "Too old for this position");
    //     return true;
    // }
}
