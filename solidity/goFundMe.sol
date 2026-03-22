//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {PriceConverter} from "./fundMeLibrary.sol";

contract GoFundMe {
    using PriceConverter for uint256;
    uint256 public timesFunded;
    address[] public funding_accounts;
    mapping(address funder => uint256 amounFunded) public AddressToAmountFunded;
    uint256 public min_USD = 2e18;
    address public owner;
    uint256 public eth_price = PriceConverter.get_eth_price();

    constructor() {
        owner = msg.sender;
    }

    function fund_me() public payable {
        timesFunded+=1;
        funding_accounts.push(msg.sender);
        AddressToAmountFunded[msg.sender] += msg.value;
        require(msg.value.get_conversion_rate() >= min_USD, "Min funding is $2 in ETH");
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

    modifier onlyOwner() {
        require(msg.sender == owner, "can only be called by contract owner.");
        _;
    }
}