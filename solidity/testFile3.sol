// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract Storage {
    string[] public names;
    mapping(string any => bytes32 hash) public stringToHash;

    function addNameToNames(string memory name) public {
        names.push(name);
    }

    function getNameByIndex(uint256 index) public view returns(string memory) {
        if (names.length == 0) {
            return "names list is empty";
        }
        string memory name = names[index];
        return name;
    }

    function clearNamesArray() public {
        names = new string[](0);
    }

    function convertToHash(string memory any) public {
        bytes32 hash = keccak256(abi.encodePacked(any));
        stringToHash[any] = hash;
    }
}