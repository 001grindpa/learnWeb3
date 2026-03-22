// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

contract SimpleStorage {
    uint8 public hasFavoriteNum;

    uint256[] listOfNumbers;

    // let's create a custome datatype
    struct Person {
        string name;
        uint256 age;
    }
    mapping(string => uint256) public nametoAgeMap;
    Person[] public listOfPeople;

    // Person public person1 = Person({name: "kelvin", age: 17});

    function storeFavoriteNum(uint8 n) public virtual {
        hasFavoriteNum = n;
    }

    function retrieve() public view returns(uint8) {
        return hasFavoriteNum;
    }

    function add_person(string memory person, uint age) public {
        listOfPeople.push(Person(person, age));
        nametoAgeMap[person] = age;
    }
}