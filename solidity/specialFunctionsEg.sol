// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract specialFunctions {
    string public result = "nothing is triggered yet";

    receive() external payable {
        result = "receive() is triggered";
    }

    fallback() external payable {
        result = "fallback() is triggered";
    }
}