// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract SimpleVotingSystem {
    uint256 public totalVotes;
    struct candidate {
        string party;
        uint256 myVotes;
    }
    mapping(string => candidate) public vote;

    // candidate public candidate1 = candidate("PDP", 0);
    // candidate public candidate2 = candidate("APC", 0);

    constructor() {
        vote["Kelvin"] = candidate("PDP", 0);
        vote["Prince"] = candidate("APC", 0);
    }
    event VoteMessage(string messages);

    function cast_vote(string memory name) public returns(string memory) {
        if (totalVotes == 10) {
            return "This voting session is over, kindly check for results.";
        }
        if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("Kelvin"))) {
            vote["Kelvin"].myVotes += 1;
            totalVotes += 1;
            return "You've successfully voted for Kelvin";
        }
        else if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("Prince"))) {
            vote["Prince"].myVotes += 1;
            totalVotes += 1;
        }
        return "Invalid input, try again.";
    }

    function election_results() public view returns(string memory) {
        if (totalVotes == 10) {
            if (vote["Kelvin"].myVotes > vote["Prnce"].myVotes) {
                return "Kelvin is the winner of this election";
            }
            else {
                return "Prince is the winner of this election";
            }
        }
        return "Elections are not yet over, check back later.";
    }
}

library parseIndex {
    
}