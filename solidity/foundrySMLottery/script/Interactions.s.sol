// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {HelperConfig, MagicNumbers} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import {Raffle} from "../src/Raffle.sol";

contract CreateSubscription is Script {
    function createSubscription(address vrfCoordinator, address account) public returns (uint256, address) {
        console.log("Creating subscription on chain id: %s", block.chainid);

        vm.startBroadcast(account);
        // typecast vrfCoordinator so that it can access the createSubscription() function
        // inherited by VRFCoordinatorV2_5Mock() from SubscriptionAPI contract
        // this function creates a unique subscription id by default without taking any arguments

        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        // a subscription is now created with a unique subscription id
        vm.stopBroadcast();

        console.log("Your subscription id is %s", subId);
        console.log("Please update the subsdcription Id in your HelperConfig.s.sol");

        return (subId, vrfCoordinator);
    }

    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;

        // function creatSubscription(){}...

        (uint256 subId,) = createSubscription(vrfCoordinator, account);
        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

// fund subscription contract
contract FundSubscription is Script, MagicNumbers {
    uint256 public constant FUND_AMOUNT = 2000 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().linkTokenAddress;
        address account = helperConfig.getConfig().account;

        // call the main fundSubscription and pass arguments
        fundSubscription(vrfCoordinator, subId, linkToken, account);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken, address account) public {
        console.log("Funding subscription: %s", subscriptionId);
        console.log("Using vrfCoordinator: %s", vrfCoordinator);
        console.log("On ChainId: %s", block.chainid);
        // 31337
        if (block.chainid == LocalChainId) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        // call main function
        addConsumer(mostRecentlyDeployed, vrfCoordinator, subId, account);
    }

    function addConsumer(address consumerContract, address vrfCoordinator, uint256 subId, address account) public {
        console.log("Adding consumer contract: %s", consumerContract);
        console.log("To vrfCoordinator: %s", vrfCoordinator);
        console.log("On Chainid %s", block.chainid);

        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, consumerContract);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}

// call and use functions from your deployed CA in broadcast
contract EnterEnterRaffle is Script {
    uint256 fundingAmount = 1 ether;

    function enterEnterRaffle(address ca) public {
        Raffle(payable(ca)).enterRaffle{value: fundingAmount}();
    }

    function run() external {
        address contractAddress = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        vm.startBroadcast();
        enterEnterRaffle(contractAddress);
        vm.stopBroadcast();
    }
}