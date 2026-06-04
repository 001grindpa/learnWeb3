// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    // == ERRORS == //
    error MerkleAirdrop__InvaidProof(address account);
    error MerkleAirdrop__UserAlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    // == CUSTOM DATATYPES == //
    /**@dev This is a struct of the txn message data that'll be hashed and used */
    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    // == STATE VARIABLES == //
    // address[] claimers;
    bytes32 private immutable I_MERKLE_ROOT;
    IERC20 private immutable I_CHIMCHIM_TOKEN;
    mapping(address claimer => bool claimed) public sClaimedUsers;
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account, uint256 amount)");

    // == SYNTACTIC SUGAR == //
    using SafeERC20 for IERC20;

    // == EVENTS == //
    event ProofConfirmed(address indexed user, uint256 indexed amount);

    constructor(bytes32 merkleRoot, address airdropToken) EIP712("Merkle Airdrop", "1") {
        I_MERKLE_ROOT = merkleRoot;
        I_CHIMCHIM_TOKEN = IERC20(airdropToken);
    }

    /** @dev This function uses EIP-712 standard to approve that a different account can claim for an
    eligible user and pay for their claiming gas, if the eligible user signs an approval to them.
     @param v This is the first signature
     @param r This is the second signature
     @param s This is the third signature
     @notice These signatures were generated during the signing process and will be used to confirm the signer
     (using an openzeppelin method that utilises ecrecover() function), then grant the secondry account 
     access to claim the tokens for the eigible user */
    function claim(address account, uint256 amount, bytes32[] calldata merkleProofs, uint8 v, bytes32 r, bytes32 s) external returns (bool) {
        if (sClaimedUsers[msg.sender] == true) {
            revert MerkleAirdrop__UserAlreadyClaimed();
        }
        // revert if the signature is invalid
        if (!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }
        // at this point we've already prepared the merkle tree offchain and gotten the original root.
        // Provided with the user address and their eligible amount, alongside the array of
        // sibling leaf hashes we'll use for climbing up the tree untill we get to the equivalent root branch hash.
        // we'll hash the address and amount then use that to climb the tree by hashing the computed hash(digest) with
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
        return true;
    }


    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(MESSAGE_TYPEHASH, AirdropClaim({
                    account: account,
                    amount: amount
                }))
            )
        );
    }

    // == PRIVATE/INTERNAL FUNCTIONS == //
    /**@notice This function is used to verify a ERC712 signature */
    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s) internal view returns (bool) {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);
        return actualSigner == account;
    }

    // == GETTERS == //
    function getTokenAdress() public view returns (IERC20) {
        return I_CHIMCHIM_TOKEN;
    }

    function getMerkleRoot() public view returns (bytes32) {
        return I_MERKLE_ROOT;
    }
}
