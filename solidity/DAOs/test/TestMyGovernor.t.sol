// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test, console } from "forge-std/Test.sol";
import { MyGovernor } from "../src/MyGovernor.sol";
import { Box } from "../src/Box.sol";
import { GovToken } from "../src/GovToken.sol";
import { TimeLock } from "../src/TimeLock.sol";

contract TestMyGovernor is Test {
    MyGovernor myGovernor;
    Box box;
    GovToken govToken;
    TimeLock timeLock;

    address public user = makeAddr("user");
    uint256 public constant INITIAL_SUPPLY = 500e18; // 500 tokens 

    uint256 public constant MIN_DELAY = 3600; // 1hr - after a vote passes
    uint256 public constant VOTING_DELAY = 1; // how many blocks till a vote is active
    uint256 public constant VOTING_PERIOD = 50400; // a period of 1 week in seconds
    
    address[] proposers;
    address[] executors;
    uint256[] public values;
    bytes[] public calldatas;
    address[] public targets;

    function setUp() external {
        // to instanciate the myGovernor contract we'll need govToken ca and 
        // timeLock contract ca
        govToken = new GovToken();
        govToken.mint(user, INITIAL_SUPPLY);
        // delegate token for voting (delegate to user)
        vm.startPrank(user);
        govToken.delegate(user); // you can delegate to other wallets
        // deploy timeLock contract
        timeLock = new TimeLock(MIN_DELAY, proposers, executors);
        // deploy governor contract
        myGovernor = new MyGovernor(govToken, timeLock);

        // create roles for the DAO
        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 adminRole = timeLock.DEFAULT_ADMIN_ROLE();
        // assign the created roles to DAO users
        timeLock.grantRole(proposerRole, address(myGovernor));
        timeLock.grantRole(executorRole, address(0)); // anybody can execute proposals
        timeLock.grantRole(adminRole, user);
        vm.stopPrank();

        box = new Box();
        box.transferOwnership(address(timeLock));
    }

    function testCantUpdateBoxWithoutGovernance() public {
        // txns to the dapp contract address should not work(revert) 
        // unless it's permited by the dao via governance
        vm.expectRevert();
        box.storeNumber(1);
    }

    function testGovernanceUpdatesBox() public {
        uint256 valueToStore = 666;
        string memory description = "store 1 to Box";
        // we'll have the my governor contract call the box store() function via calldata
        // remember we're using calldata becaus the myGovernor function that does this call is configured
        // to be able to call any contract function or send eth from it's bal to any address
        bytes memory encodedFunctionCall = abi.encodeWithSignature("storeNumber(uint256)", valueToStore);

        values.push(0);
        calldatas.push(encodedFunctionCall);
        targets.push(address(box));

        // 1. Propose to the DAO
        uint256 proposalId = myGovernor.propose(targets, values, calldatas, description);

        // view the proposal state
        console.log("Proposal state: ", uint256(myGovernor.state(proposalId)));
        // check the enum body to see what index represents what state

        // fastforward to when vote becomes active
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1); // roll the block to 2 blocks upfront

        // check vote status again
        console.log("Proposal state: ", uint256(myGovernor.state(proposalId)));

        // 2. Vote with reason
        string memory reason = "cuz i'm testing for stuff";

        uint8 voteWay = 1; // voting yes - enum attribute
        vm.prank(user);
        myGovernor.castVoteWithReason(proposalId, voteWay, reason);

        // fastforward to 1 week
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1); // roll the current block to 50000+ blocks upfront

        // 3. Queue the tx
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        myGovernor.queue(targets, values, calldatas, descriptionHash);

        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY + 1);

        // 4. Execute
        myGovernor.execute(targets, values, calldatas, descriptionHash);

        console.log("Stored Number: ", box.getNumber());
        assertEq(box.getNumber(), valueToStore);
    }
}