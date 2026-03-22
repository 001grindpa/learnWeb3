// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./fundMeLibrary.sol";

error notOwner();

contract GoFundMe {
    using PriceConverter for uint256;
    uint256 public timesFunded;
    address[] public funding_accounts;
    mapping(address funder => uint256 amounFunded) public AddressToAmountFunded;
    uint256 constant public MIN_USD = 2e18;
    address immutable public i_owner;
    uint256 public eth_price = PriceConverter.get_eth_price();

    constructor() {
        i_owner = msg.sender;
    }

    function fund_me() public payable {
        timesFunded+=1;
        funding_accounts.push(msg.sender);
        AddressToAmountFunded[msg.sender] += msg.value;
        require(msg.value.get_conversion_rate() >= MIN_USD, "Min funding is $2 in ETH");
    }

    function withdraw() public onlyOwner {
        for (uint256 i; i < funding_accounts.length; i++) {
            address funder = funding_accounts[i];
            AddressToAmountFunded[funder] = 0;
        }
        funding_accounts = new address[](0);

        // let's integrate a sending algorithm using "call"
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "call error");
    }

    function getVersion() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return priceFeed.version();
    }

    receive() external payable {
        fund_me();
    }

    fallback() external payable {
        fund_me();
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "can only be called by contract owner.");
        if (msg.sender != i_owner) {revert notOwner();}
        _;
    }
}