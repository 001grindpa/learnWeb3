// SPDX-License-Identifier: MIT

// Layout of Contract:
// license
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

pragma solidity ^0.8.18;
import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Decentralized Stable Token
 * @author Grindpa
 * @notice Stable token properties;
 * - type: pegged
 * - stability: Algorithmic
 * - collateralization: Exogenous
 * @notice This is the contract meant to be governed by DSCEngine. This contract is just the ERC20 implementation of our stablecoin
 */

contract DecentralisedStableCoin is ERC20Burnable, Ownable {
    // errors
    error DecentralisedStableCoin__CanNotBurnZeroAmount(uint256 amnt);
    error DecentralisedStableCoin__BurnAmountExceedsBalance(uint256 amnt);
    error DecentralisedStableCoin__CanNotMintToNullAddress(address to);
    error DecentralisedStableCoin__MintAmountMustBeMoreThanZero(uint256 amnt);

    constructor() ERC20("DecntralizedStableCoin", "DSC") Ownable(msg.sender) {}

    /**
     * @dev This function configures the burning mechanism of our token
     * @param _amount It takes an uint256 value as argument for amount to be burnt
     */
    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        // revert if burning amount is less than wallet balance
        if (_amount <= 0) {
            revert DecentralisedStableCoin__CanNotBurnZeroAmount(_amount);
        }
        if (balance < _amount) {
            revert DecentralisedStableCoin__BurnAmountExceedsBalance(balance);
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        // sanitize incoming arguments
        if (_to == address(0)) {
            revert DecentralisedStableCoin__CanNotMintToNullAddress(_to);
        }
        if (_amount <= 0) {
            revert DecentralisedStableCoin__MintAmountMustBeMoreThanZero(_amount);
        }
        _mint(_to, _amount);
        return true;
    }

    // Implement getter functions
    function getBalance(address user) public view returns (uint256) {
        return balanceOf(user);
    }
}
