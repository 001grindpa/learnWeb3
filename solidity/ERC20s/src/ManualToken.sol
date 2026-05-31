// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract ManualToken {
    // errors
    error ManualToken__InvalidTransfer(uint256 _fromBal, uint256 _toBal);

    mapping(address owner => uint256 balance) private sBalance;

    function name() public pure returns (string memory) {
        return "Manual Token";
    }

    function totalSupply() public pure returns (uint256) {
        return 100 ether; // supply size in ether
        // in wei 100 ether is 100e18
    }

    function decimals() public pure returns (uint8) {
        return 18; 
        // Defines the scaling factor: tells the UI to shift the decimal point 18 places to the left for display
        // in a human readable way, since all eth values (in ether) is usually used or sent out in wei.
        // wei has extra 18 zeros after the actual ether value it's converting from.
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return sBalance[_owner];
    }

    function transfer(address _to, uint256 _amount) public {
        // s_balance[msg.sender] = address(msg.sender).balance;
        // s_balance[_to] = address(_to).balance;

        // uint256 initialBalance = balanceOf(msg.sender) + balanceOf(_to);
        // s_balance[msg.sender] -= _amount;
        // s_balance[_to] += _amount;
    }
}