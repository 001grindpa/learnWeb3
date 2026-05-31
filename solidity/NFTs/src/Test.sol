// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
@title testing random stuff
@author grindpa
@dev this function may have tools imported for testing purposes
 */

 contract Random {
    // declare errors

    // declare events

    // declare datatypes

    // declare state variables
    // string public name = "Kelvin";

    /**
    @notice this function execcutes a concatenated string
    @param name name of user
    @return string the concatenated string output
     */
    function sayHello(string memory name) public pure returns (string memory) {
        string memory result = string.concat(
            'Hello my name is ',name,', nice to meet you'
        );
        return result;
    }
 }