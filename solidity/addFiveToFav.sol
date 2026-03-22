// SPDX-License-Identifier: MIT

import {SimpleStorage} from "./simpleStorage.sol";

contract addFiveToFav is SimpleStorage {
    // function sayHello() public pure returns(string memory) {
    //     return "Hello, world";
    // }
    function storeFavoriteNum(uint8 n) public override {
        hasFavoriteNum = n + 5;
    }
}