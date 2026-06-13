// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {CarDealership} from "../src/test.sol";
import {Vm} from "forge-std/Vm.sol";

contract TestCarDealership is Test {
    CarDealership carDealership;
    address user;
    uint256 pk;

    function setUp() external {
        (user, pk) = makeAddrAndKey("user");
        carDealership = new CarDealership();
    }

    function testIfCarIsAvailable() public {
        vm.prank(user);
        bool status = carDealership.isAvailable("Tesla", "Model 3", 2023);
        assert(status == true);
    }

    function testPurchaseCar() public {
        vm.startPrank(user);
        carDealership.buyCar("BMW", "X5", 2024); // first purchase
        carDealership.buyCar("Tesla", "Model 3", 2023); // second purchase
        vm.stopPrank();

        uint256 numberOfCars = carDealership.getCarsPurchased(user);

        // console.log(numberOfCars);
        assertEq(numberOfCars, 2);
    }

    function testEmittedEventIsCorrect() public {
        string memory expectedBrandname = "BMW";
        vm.startPrank(user);
        vm.recordLogs();
        carDealership.buyCar(expectedBrandname, "X5", 2024);
        vm.stopPrank();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        string memory brandName = abi.decode(entries[0].data, (string));
        // console.log(brandName);
        assertEq("BMW", brandName);
    }

    function testRandomUserCantAddCarToStock() public {
        vm.prank(user);
        vm.expectRevert(); // only contract deployer can add to stock
        carDealership.stockMoreCars("Mercedes-Benz", "C-Class", 2022);
    }

    function testAddNewCarToStock() public {
        vm.startPrank(address(this));
        carDealership.stockMoreCars("Mercedes-Benz", "C-Class", 2022);
        uint256 carsInStock = carDealership.getTotalCarsInStock();
        vm.stopPrank();
        console.log(carsInStock);
    }
}