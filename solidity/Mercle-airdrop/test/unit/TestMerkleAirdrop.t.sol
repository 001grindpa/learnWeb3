// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {ChimChimToken} from "../../src/ChimChimToken.sol";
import {MerkleAirdrop} from "../../src/MerkleAirdrop.sol";
import {DeployMerkleAirdrop} from "../../script/DeployMerkleAirdrop.s.sol";

contract TestMerkleAirdrop is Test {
    MerkleAirdrop public merkleAirdrop;
    ChimChimToken public cct;
    DeployMerkleAirdrop public deployer;

    bytes32 public ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    bytes32[] public PROOFS = [bytes32(0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a),
    bytes32(0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576)];

    function setUp() public {
        cct = new ChimChimToken();
        deployer = new DeployMerkleAirdrop();
        (merkleAirdrop, cct) = deployer.run();

        // mint 100e18 cct tokens to deployed contract
        cct.mint(address(merkleAirdrop), 100e18);
    }

    function testMerkleRootIsCorrect() public {
        vm.prank(msg.sender);
        bytes32 receivedRoot = merkleAirdrop.getMerkleRoot();

        assertEq(receivedRoot, ROOT);
    }

    function testUserIsEligible() public {
        uint256 contractStartingBal = cct.balanceOf(address(merkleAirdrop));
        address user = 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D;
        uint256 eligibleAmount = 25000000000000000000; // 25e18
        uint256 initialBal = cct.balanceOf(user);

        vm.prank(user);
        bool status = merkleAirdrop.claim(user, eligibleAmount, PROOFS);
        uint256 currentBal = cct.balanceOf(user);
        uint256 contractEndingBal = cct.balanceOf(address(merkleAirdrop));
        
        console.log("Initial Bal:", initialBal);
        console.log("Current Bal:", currentBal);

        assertEq(status, true);
        assert(contractStartingBal == contractEndingBal + currentBal);
    }
}
