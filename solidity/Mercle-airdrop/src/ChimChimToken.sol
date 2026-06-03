// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ChimChimToken is ERC20, Ownable {
    // == ERRORS == //
    error ChimChimToken__CheckRecieverAddressOrAmount(address to, uint256 amount);

    constructor()ERC20("ChimChim Token", "CCT") Ownable(msg.sender) {}

    function mint(address to, uint256 amount) public {
        if (to == address(0) || amount == 0) revert ChimChimToken__CheckRecieverAddressOrAmount(to, amount);
        _mint(to, amount);
    }
}