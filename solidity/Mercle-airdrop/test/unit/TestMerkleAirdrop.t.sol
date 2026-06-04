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
    address public user;
    uint256 public pk;
    address public GAS_PAYER;

    bytes32 public ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    bytes32[] public PROOFS = [bytes32(0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a),
    bytes32(0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576)];

    function setUp() public {
        // our addy and pk
        (user, pk) = makeAddrAndKey("user");
        // this user will claim for us
        GAS_PAYER = makeAddr("gasPayer");
        // fund gaPayer and user
        vm.deal(GAS_PAYER, 1 ether);
        vm.deal(user, 1 ether);

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

    function testUserIsEligibleAndClaim() public {
        uint256 contractStartingBal = cct.balanceOf(address(merkleAirdrop));
        uint256 eligibleAmount = 25000000000000000000; // 25e18
        uint256 initialBal = cct.balanceOf(user);
        

        vm.startPrank(user);
        // get messageData hash
        bytes32 digest = merkleAirdrop.getMessageHash(user, eligibleAmount);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        vm.stopPrank();

        vm.prank(GAS_PAYER);
        bool status = merkleAirdrop.claim(user, eligibleAmount, PROOFS, v, r, s);
        uint256 currentBal = cct.balanceOf(user);
        uint256 contractEndingBal = cct.balanceOf(address(merkleAirdrop));
        
        console.log("Initial Bal:", initialBal);
        console.log("Current Bal:", currentBal);

        assertEq(status, true);
        assert(contractStartingBal == contractEndingBal + currentBal);
    }
}
