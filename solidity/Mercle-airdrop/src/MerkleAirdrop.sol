// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    // == ERRORS == //
    error MerkleAirdrop__InvaidProof(address account);
    error MerkleAirdrop__UserAlreadyClaimed();

    // address[] claimers;
    bytes32 private immutable I_MERKLE_ROOT;
    IERC20 private immutable I_CHIMCHIM_TOKEN;
    mapping(address claimer => bool claimed) public sClaimedUsers;

    // == SYNTACTIC SUGAR == //
    using SafeERC20 for IERC20;

    // == EVENTS == //
    event ProofConfirmed(address indexed user, uint256 indexed amount);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) {
        I_MERKLE_ROOT = merkleRoot;
        I_CHIMCHIM_TOKEN = airdropToken;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProofs) external {
        if (sClaimedUsers[msg.sender] == true) {
            revert MerkleAirdrop__UserAlreadyClaimed();
        }
        // at this point we've already prepared the merkle tree offchain and gotten the original root.
        // Provided with the user address and their eligible amount, alongside the array of 
        // sibling leaf hashes we'll use for climbing up the tree untill we get to the equivalent root branch hash
        // we'll hash the address and amount then use that to climb the tree by hashing the computed hash with
        // the first array sibling leaf hash, and continue that for the next sibling and so forth.
        // we're using a double-hash optimisation for extra uniqueness
        bytes32 leaf = keccak256(abi.encodePacked(keccak256(abi.encode(account, amount))));
        // "leaf" is the first computed hash, we'll pass leaf alongside the sibling arrays and the original tree root
        // to the MerkleProof() function so that it auto climbs the tree and compare the final computedHash with the
        // passed root, if they match, then the user is truly eligible with that amount, the MerkleProof() returns
        // a bool (true), if it does not match with the original root, it means the user is not on the tree/eligible
        // the function returns false
        sClaimedUsers[msg.sender] = true;
        if (!MerkleProof.verify(merkleProofs, I_MERKLE_ROOT, leaf)) {
            revert MerkleAirdrop__InvaidProof(account);
        }
        emit ProofConfirmed(account, amount);
        // we're using safe transfer so it handles errors better
        I_CHIMCHIM_TOKEN.safeTransfer(account, amount);
    }

    // == GETTERS == //
    function getTokenAdress() public view returns (IERC20) {
        return I_CHIMCHIM_TOKEN;
    }

    function getMerkleRoot() public view returns (bytes32) {
        return I_MERKLE_ROOT;
    }
}