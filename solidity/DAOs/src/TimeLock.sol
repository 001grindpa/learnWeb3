// SPDX-License-Identifer: MIT
pragma solidity ^0.8.18;

import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";

contract TimeLock is TimelockController {
    /**
    * @notice The TimelockContoller parent contract has a constructor that takes arguments.
    * we need to implement a constructor that passes the neccesary arguments to it
    * @param minDelay initial minimum delay in seconds for operations
    * @param proposers accounts to be granted proposer and canceller roles
    * @param executors accounts to be granted executor role
    * admin - optional account to be granted admin role; disable with zero address
    * we'll just pass the admin address directly to the parent's constructor as last argument
     */
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors) 
    TimelockController(minDelay, proposers, executors, msg.sender) {}
}
