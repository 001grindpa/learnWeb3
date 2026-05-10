// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test {
    // events
    event RaffledSuccessfully(address indexed player);
    event WinnerPicked(address indexed winner);

    // declare state variable
    Raffle public raffle;
    HelperConfig public helperConfig;

    // declare a test user
    address public USER = makeAddr("user");
    // give it some test eth
    uint256 public STARTING_BAL = 5 ether;

    // funding amount
    uint256 FUNDING = 0.1 ether;

    // anvil chain id
    uint256 public LOCAL_CHAIN_ID = 31337;

    // declare all networkConfig struct variables statefully
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;

    function setUp() external {
        vm.deal(USER, STARTING_BAL);

        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfig();

        entranceFee = networkConfig.entranceFee;
        interval = networkConfig.interval;
        vrfCoordinator = networkConfig.vrfCoordinator;
        gasLane = networkConfig.gasLane;
        callbackGasLimit = networkConfig.callbackGasLimit;
        subscriptionId = networkConfig.subscriptionId;
    }

    // modifiers
    modifier upkeepNeededIsTrue {
        vm.prank(USER);
        raffle.enterRaffle{value: FUNDING}();
        uint256 lastTimeStamp = raffle.getLastTimestamp();
        vm.warp(lastTimeStamp + interval + 2);
        vm.roll(block.number + 1);

        _;
    }

    modifier skipMockCoordinatorUse() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    // test functions

    function testRaffleInitializedInOpenState() public view {
        assert(raffle.getState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnought() public {
        vm.prank(USER);
        vm.expectRevert(Raffle.Raffle__fundMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        vm.prank(USER);
        raffle.enterRaffle{value: 0.1 ether}();

        // assert(raffle.getTotalParticipants() == 1);
        assert(raffle.getParticipant(0) == USER);
    }

    function testEnteringRaffleEmitsEvent() public {
        vm.prank(USER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffledSuccessfully(USER);

        raffle.enterRaffle{value: 0.1 ether}();
    }

    function testDontAllowNewParicipantsWhenCalculating() public upkeepNeededIsTrue {
        // start by funding and populating contract
        // vm.prank(USER);
        // raffle.enterRaffle{value: 0.1 ether}();
        // vm.warp(block.chainid + interval + 1);
        // vm.roll(block.number + 1);

        // Action
        raffle.performUpkeep("");

        //new interval has come (as per vm.warp() cheatcode), raffle is trying to pick winner(CALCULATING state)
        //let's try to enter raffle in this moment
        vm.prank(USER);
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffle.enterRaffle{value: 0.1 ether}();
    }

    /* == TEST CHECKUPKEEP FUNCTION ARTRIBUTES == */

    // bool timeHasPassed = ((block.timestamp - s_lastTimestamp) > I_INTERVAL);
    // bool isOpen = s_raffleState == RaffleState.OPEN;
    // bool hasPlayers = s_participants.length > 0;
    // bool hasBalance = address(this).balance > 0;
    // upkeepNeeded = timeHasPassed && isOpen && hasPlayers && hasBalance;
    function testCheckUpkeepReturnsFalseIfContractHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckupkeepReturnsFalseIfRaffleIsNotOpen() public upkeepNeededIsTrue {
        // Arrange
        // vm.prank(USER);
        // raffle.enterRaffle{value: 1 ether}();
        // vm.warp(block.timestamp + interval + 1);
        // vm.roll(block.number + 1);
        raffle.performUpkeep("");

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    // Challenge
    // testCheckUpkeepReturnsFalseIfNotEnoughTimeHasPassed
    // testCheckUpkeepReturnsTrueWhenParametersAreGood
    function testCheckUpkeepReturnsFalseIfNotEnoughTimeHasPassed() public {
        // Arrange
        vm.prank(USER);
        raffle.enterRaffle{value: 0.1 ether}();

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public upkeepNeededIsTrue {
        // Arrange
        // vm.prank(USER);
        // raffle.enterRaffle{value: 0.1 ether}();
        // vm.warp(block.timestamp + interval + 1);
        // vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        // Assert
        assert(upkeepNeeded);
    }

    function testVrfCoordinatorValueIsLegit() public {
        address vrfCoordinator_ = helperConfig.getConfig().vrfCoordinator;

        assertEq(vrfCoordinator_, vrfCoordinator);
        // assert(vrfCoordinator_ == vrfCoordinator);
    }

    function testSubscriptionIdValueIsLegit() public {
        uint256 subId = helperConfig.getConfig().subscriptionId;

        assertEq(subId, subscriptionId);
    }

    /* == TEST PERFORMUPKEEP FUNCTION ARTRIBUTES == */
    function testPerformupkepCanOnlyRunIfCheckupkeepIsTrue() public {
        // Arrange
        vm.prank(USER);
        raffle.enterRaffle{value: 1 ether}();
        vm.warp(block.timestamp + interval + 1);

        // Act
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
        uint256 currentBalance = 0;
        Raffle.RaffleState rState = raffle.getState();

        // Act
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle_UpkeepNotNeeded.selector, currentBalance, rState)
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public upkeepNeededIsTrue {
        // Arrange
        // vm.prank(USER);
        // raffle.enterRaffle{value: 0.1 ether}();
        // vm.warp(block.timestamp + interval + 1);
        // vm.roll(block.number + 1);

        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // Assert
        Raffle.RaffleState raffleState = raffle.getState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    /* FULFILLRANDOMWORDS */
    /** @notice We'll be testing out fulfillRandomWords in this section */
    function testFulfillRandomWordsCanOnlyBeCalledAfterperformUpkeep(uint256 randomRequestId) public upkeepNeededIsTrue skipMockCoordinatorUse {
        // Arrange
        // vm.prank(USER);
        // raffle.enterRaffle{value: 0.1 ether}();
        // vm.warp(block.timestamp + interval + 1);
        // vm.roll(block.number + 1);

        // Act
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
        console.log("Succesfull revert");
    }

    function testFulfillRandomWordsPickAWinnerResetsAndSendsMoney() public upkeepNeededIsTrue skipMockCoordinatorUse {
        // Arrange
        // vm.prank(USER);
        // raffle.enterRaffle{value: 0.1 ether}();
        // vm.warp(block.timestamp + interval + 1);
        // vm.roll(block.number + 1);
        // Arrange
        uint256 additionalParticipants = 3; // we have 4 participants in total since first one already entered from modifier (upkeepNeededIsTrue)
        uint256 startingIndex = 1;
        address expectedWinner = address(1);

        for (uint256 i = startingIndex; i < startingIndex + additionalParticipants; i++) {
            // create new player
            address newPlayer = address(uint160(i));
            // fund and prank with new player
            hoax(newPlayer, 1 ether);
            raffle.enterRaffle{value: FUNDING}();
        }
        uint256 startingTimeStamp = raffle.getLastTimestamp();
        uint256 winnerStartingBalance = expectedWinner.balance;
        // Act
        /* record the performUpkeep's (performUpkeep) event logs in memory and retrieve the
         requestId(random generated number) from the second log's topic array second index
         from memory
         For our Mock contract vrfCoordinator, the default requestId(supposed random number) is 0 and increases by 1 for each request,
         although it's not random but it mimicks a live contract's 'requestRandomWords()' function's randomness
         as it increases by 1 for each request. Because of this, the raffle winner is always known on a local chain(anvil);
         usually the first address in the participant's array which has an index of 0. this is important because
         now we can see if the fullfilRandomWords function from raffle contract actually sends
         those funds to the picked winner(we know the picked winner with mock vrfcoordinator as stated earlier), 
         resets the array of participants and changes the raffle state back to OPEN*/

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        uint256 s_requestId = uint256(requestId);

        /** @dev
        -> In live networks: once Raffle calls requestRandomWords (in performUpkeep), 
        you do nothing else. The decentralized chainlink Oracle Network(DON) "listens"
        for an event, generates the random number off-chain, and then initiates
        its own transaction to call rawFulfillRandomWords(which triggers your fulfillRandomWords as callback)
        on the Raffle contract. rawFulfillRandomWords is a function of VRFConsumerBaseV2Plus(parent of Raffle)
        recall fulfillRandomWords is overriden in our Raffle contract and receives the random numbers sent by the Oracle

        -> In this Test(we'll use mock): The local foundry environment has no off-chain nodes to "listen"
        for the request. The VRFCoordinatorV2_5Mock is just a passive contract, you must manually
        call it in this test script to simulate the Oracle fulfilling the request.
         */

        // call fulfillRandomWords from vrfCoordinator contract and pass a valid requestId this time.
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(s_requestId, address(raffle));
        // Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getState();
        uint256 winnerBalance = address(recentWinner).balance;
        uint256 endingTimeStamp = raffle.getLastTimestamp();
        uint256 prize = address(raffle).balance; // (additionalParticipants + 1) * FUNDING
        // console.log(raffleState);+
        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0);
        assert(endingTimeStamp > startingTimeStamp);
    }
}
