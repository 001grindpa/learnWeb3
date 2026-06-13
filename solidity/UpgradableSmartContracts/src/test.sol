//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
* @title Car Dealership
* @notice This contract is used for testing out random stuff
 */
contract CarDealership {
    // errors
    error CarDealership__ThiscarIsNotAvailable(string model);
    error CarDealership__OnlyAdminCanCallThisFunction();

    // syntatic sugers

    // custome types
    struct Car {
        string brand;
        string model;
        uint256 year;
    }

    // state variables
    address public Dealer;
    uint256 public totalAvailableCars;
    mapping(string brand => mapping(string model => uint256 year)) public sAvailableCars;
    mapping(address buyer => Car[] car) public sCarsPurchased;

    // events
    event SuccessfulPurchase(string name);

    // modifiers
    modifier OnlyAdmin {
        if (msg.sender != Dealer) {
            revert CarDealership__OnlyAdminCanCallThisFunction();
        }
        _;
    }

    // special functions
    constructor() {
        // assign contract owner
        Dealer = msg.sender;

        // stock cars
        sAvailableCars["Toyota"]["Corolla"] = 2023;
        sAvailableCars["Honda"]["Civic"] = 2022;
        sAvailableCars["Ford"]["Mustang"] = 2024;
        sAvailableCars["Tesla"]["Model 3"] = 2023;
        sAvailableCars["BMW"]["X5"] = 2024;
        totalAvailableCars = 5;
    }

    // public/external functions
    function isAvailable(string memory brand, string memory model, uint256 year) public view returns(bool) {
        if (sAvailableCars[brand][model] == year) {
            return true;
        }
        revert CarDealership__ThiscarIsNotAvailable(model);
    }

    function buyCar(string memory brand, string memory model, uint256 year) public returns (string memory) {
        // check if car is available first
        isAvailable(brand, model, year);

        // create a car struct object
        Car memory car = Car({
            brand: brand,
            model: model,
            year: year
        });
        sCarsPurchased[msg.sender].push(car);
        emit SuccessfulPurchase(brand);
        return "Successful purchase";
    }

    // getters
    function getCarsPurchased(address owner) public view returns (uint256) {
        return sCarsPurchased[owner].length;
    }
}