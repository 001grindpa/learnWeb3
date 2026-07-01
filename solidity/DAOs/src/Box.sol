// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract Box is Ownable {
    // === STATE VARIABLE === //
    uint256 public sNumber;

    // === EVENTS === //
    event NumberChanged(uint256 newValue);

    // === SPECIAL FUNCTIONS === //
    constructor() Ownable(msg.sender) {}

    // === PUBLIC FUNCTIONS === //
    function storeNumber(uint256 newNumber) public onlyOwner {
        sNumber = newNumber;

        emit NumberChanged(newNumber);
    }

    // === GETTERS === //
    function getNumber() external view returns (uint256) {
        return sNumber;
    }
}
