// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {console} from "../lib/forge-std/src/console.sol";

// NatSpec config
/**
 * @title A simple Raffle contract
 * @author Anyanwu Francis
 * @notice This contract is for creating a simple raffle
 * @dev Implements Chainlink VRFv2.5
 */

contract Raffle is VRFConsumerBaseV2Plus {
    // custom errors
    error Raffle__fundMoreToEnterRaffle();
    error Raffle__withdrawUnsuccessful();
    error Raffle__RaffleNotOpen();
    error Raffle_UpkeepNotNeeded(uint256 balance, uint256 state);
    error Raffle__NoParticipantsInRaffle(address payable[] participants);

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    // state variables
    address payable[] private s_participants;
    // @dev the duration of the lottery in seconds
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable I_ENTRANCE_FEE;
    uint256 private immutable I_INTERVAL;
    bytes32 private immutable I_KEY_HASH;
    uint256 private immutable I_SUBSCRIPTION_ID;
    uint32 private immutable I_CALLBACK_GASLIMIT;
    // storage variable to store the last raffle time snapshot
    uint256 private s_lastTimestamp;
    address payable private s_recentWinner;
    RaffleState private s_raffleState;

    // events
    event RaffledSuccessfully(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address _vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGaslimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        I_ENTRANCE_FEE = entranceFee;
        I_INTERVAL = interval;
        I_KEY_HASH = gasLane;
        I_SUBSCRIPTION_ID = subscriptionId;
        I_CALLBACK_GASLIMIT = callbackGaslimit;

        s_lastTimestamp = block.timestamp;
        // default our raffle_state to being open
        s_raffleState = RaffleState.OPEN; // or -> s_raffleState = RaffleState(0); since enum states are indexed.
    }

    // number of participants getter
    /**
     * @notice - This function gets the total number of participants
     * @return - length of participants array
     */
    function getTotalParticipants() external view returns (uint256) {
        return s_participants.length;
    }

    // get a specific user from array
    /**
     * @notice - This function is used to get a specific user address
     * @param - an unsigned integer is passed as index to retrieve address positionally
     * @return - user address from participants array
     */
    function getParticipant(uint256 index) external view returns (address) {
        return s_participants[index];
    }

    // state getter function
    /**
     * @notice - This function is used to check the state of the contract
     * @return - contract(Raffle) state
     */
    function getState() external view returns (RaffleState) {
        return s_raffleState;
    }

    // send functions
    function enterRaffle() external payable {
        if (msg.value < I_ENTRANCE_FEE) revert Raffle__fundMoreToEnterRaffle();
        if (s_raffleState != RaffleState.OPEN) revert Raffle__RaffleNotOpen();

        s_participants.push(payable(msg.sender));

        // call successfull participation event
        emit RaffledSuccessfully(address(msg.sender));
    }

    // when should the winner be picked
    /**
     * @dev Ths is the function that chainlink node will call if the lottery is ready to have a winner picked.
     * The following should be true in ordrer for upkeepNeeded to be true:
     * 1. The time interval has passed between raffle runs
     * 2. The lottery is open
     * 3. The contract has ETH
     * 4. Implicitly, your subscription has LINK
     * @param - ignored(it's supposed to be checkData)
     * @return upkeepNeeded true if it's time to restart the lottery
     */
    function checkUpkeep(bytes memory /* checkData */)public view returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        // use ternary perations to assign bool value for condition block
        bool timeHasPassed = (block.timestamp - s_lastTimestamp) >= I_INTERVAL;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasPlayers = s_participants.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasPlayers && hasBalance;
        // console.log(isOpen, timeHasPassed, hasPlayers, hasBalance);
        return (upkeepNeeded, "");
    }

    // performUpkeep() function is performUpkeep()
    /**
     * @dev This function is auto called by chainlink automations every second
     * @notice All this function does is run an algorithm that sends a random number to the consumer(VRFConsumerBaseV2)
     * @param (performData) unused; required by Chainlink Automation interface. Pass an empty string.
     */
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upKeepNeeded,) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Raffle_UpkeepNotNeeded(address(this).balance, uint256(s_raffleState));
            // s_raffleState is wrapped in a uint256() since it's a RaffleState datatype by default but returns a number (0, 1 etc -> index)
        }

        // @dev change the default enum to calculating, so that enterRaffle() is reverted when someone tries to join the raffle as winner is being picked.
        s_raffleState = RaffleState.CALCULATING;

        // RandomWordsRequest is a declared struct inside VRFV2PlusClient library, 'request' is just the struct type
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            // key_hash -> gas price
            keyHash: I_KEY_HASH,
            // subscription_id -> allows us to fund the oracle subscription
            subId: I_SUBSCRIPTION_ID,
            // request_confirmation -> allows us to choose how many confirmation blocks until txn is processed
            requestConfirmations: REQUEST_CONFIRMATION,
            // callback_gasLimit -> allows us to limit the amount of gas a callback should use
            callbackGasLimit: I_CALLBACK_GASLIMIT,
            // num_words -> allows us to choose how many rand num we want
            numWords: NUM_WORDS,
            // extraArgs -> allows us to choose what curency we want to pay gas in
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });
        // we'll pass our implemented request struct into the requestRandomWords function as an argument
        /*uint256 requestId = */
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestedRaffleWinner(requestId); // emitting this event is redundant because s_vrfCoordinator contract also emits it as well
        // we're emitting the event for learning and testing sake, line 164-165 is not neccessary.
        // manually getting requestId is not important on a live network, but we need it here so we can manually
        // use it in our test script when calling fulfillRandomWords from vrfCoordinator(oracle simulator) to
        // call and send random words arguments to fulfillRandomWords in VRFCoordinatorV2_5Mock
    }

    /**
    * @dev fulfillRandomWords() uses the modulo operator to scale down the large random number received from the vrfCoordinator oracle
    * @notice This function picks a random raffle participant
    * @notice Even one random number is passed in an array
    * @param randomWords this is the array of long length random numbers
     */

    function fulfillRandomWords(uint256,/* requestId */uint256[] calldata randomWords)
        internal
        override
    {
        if (s_participants.length == 0) {revert Raffle__NoParticipantsInRaffle(s_participants);}
        // use modulus on the received
        uint256 indexOfWinner = randomWords[0] % s_participants.length;
        address payable recentWinner = s_participants[indexOfWinner];

        s_recentWinner = recentWinner;
        s_participants = new address payable[](0);

        s_raffleState = RaffleState.OPEN;

        s_lastTimestamp = block.timestamp;

        // log an event after winner is selected
        emit WinnerPicked(s_recentWinner);

        (bool success,) = s_recentWinner.call{value: address(this).balance}("");
        if (!success) revert Raffle__withdrawUnsuccessful();
    }

    // getter/call functions
    function getRafflePrice() external view returns (uint256) {
        return I_ENTRANCE_FEE;
    }

    function getLastTimestamp() external view returns (uint256) {
        return s_lastTimestamp;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
