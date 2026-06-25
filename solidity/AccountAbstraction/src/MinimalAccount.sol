// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract MinimalAccount is IAccount, Ownable {
    // == ERRORS == //
    error MinimalAccount__NotFromEntryPoint(address caller);
    error MinimalAccount__NotFromEntryPointOrOwner(address caller);
    error MinimalAccount__CallFailed(bytes data);

    // == STATE VARIABLES == //
    IEntryPoint private immutable I_ENTRY_POINT;

    // == MODIFIERS == //
    modifier requireFromEntryPoint() {
        if (msg.sender != address(I_ENTRY_POINT)) {
            revert MinimalAccount__NotFromEntryPoint(msg.sender);
        }
        _;
    }

    modifier requireEntryPointOrOwner() {
        if (msg.sender != address(I_ENTRY_POINT) && msg.sender != owner()) {
            revert MinimalAccount__NotFromEntryPointOrOwner(msg.sender);
        }
        _;
    }

    // == SPECIAL FUNCTIONS == //
    constructor(address entryPoint) Ownable(msg.sender) {
        I_ENTRY_POINT = IEntryPoint(entryPoint);
    }

    receive() external payable {}

    // == PUBLIC/EXTERNAL FUNCTIONS == //
    /**
     * @notice This function allows the smart wallet to interact with any type function from
     * any contract when the contract address of that contract and the function calldata is given
     * @param des The contract address we're interacting with
     * @param val The value of eth if we want to send eth to the provided contract from our balance
     * pass 0 if no eth is required to be sent
     * @param funcData encoded calldata containing contract function name alongside it's
     * passed param value, encoded with 'abi.encodeWithSelector("selector", params...)'
     * pass empty string if no calldata is required to be interacted with.
     */
    function execute(address des, uint256 val, bytes calldata funcData) external requireEntryPointOrOwner {
        (bool success, bytes memory result) = des.call{value: val}(funcData);
        if (!success) {
            revert MinimalAccount__CallFailed(result);
        }
    }

    // == INTERNAL/PRIVATE FUNCTIONS == //
    /**
     * @dev                          Import the 'PackedUserOperation' struct since our inherited function makes
     *                               use of it's instance/object as argument
     * @param userOp                 This is the txn data the Entery point contract forwards to our contract wallet
     * @param userOpHash             Hash of the user's request data. can be used as the basis for signature.
     * @param missingAccountFunds -  Missing funds on the account's deposit in the entrypoint.
     *                               This is the minimum amount to transfer to the sender(entryPoint) to be
     *                               able to make the call. The excess is left as a deposit in the entrypoint
     *                               for future calls. Can be withdrawn anytime using "entryPoint.withdrawTo()".
     *                               In case there is a paymaster in the request (or the current deposit is high
     *                               enough), this value will be zero.
     * @return validationData         - Packaged ValidationData structure. use `_packValidationData` and
     *                                `_unpackValidationData` to encode and decode.
     *                                <20-byte> aggregatorOrSigFail - 0 for valid signature, 1 to mark signature failure,
     *                                otherwise, an address of an "aggregator" contract.
     *                                <6-byte> validUntil - Last timestamp this operation is valid at, or 0 for "indefinitely"
     *                                <6-byte> validAfter - First timestamp this operation is valid
     *                                                    If an account doesn't use time-range, it is enough to
     *                                                    return SIG_VALIDATION_FAILED value (1) for signature failure.
     *                                Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        requireFromEntryPoint
        returns (uint256 validationData)
    {
        // let's start by validating the incoming userOp signature
        // create an internal function (_validateSignature()) to handle this
        validationData = _validateSignature(userOp, userOpHash);
        // _validateNonce() // we're not going to write the nonce validation for this contract but it's important as well
        _payPrefund(missingAccountFunds);
    }

    // EIP-191 version of the signed hash
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        returns (uint256 validationData)
    {
        // implement code that retrieves the EIP-191 message hash (i.e 0x19 + message string) from the incoming userOperation txn hash
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        // implement code that recovers signer's public address from the retrieved message hash and signature hasg
        // userOp.signature is the signature hash string
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);
        // check if the signer is thesame as this contract wallet owner
        /**
         * @dev _owner which stores the owner address from the Ownable contract is a private state variable
         * to get it, we use the owner() public function.
         * @notice SIG_VALIDATION_FAILED and SIG_VALIDATION_SUCCESS are variables that hold 1 and 0 respectively
         * this is just because we don't want to use magic numbers, else you can just slap in 1 and 0 in their positions
         * or rather than import them, we can just declare them in this same contract. But we're following the
         * account-abstraction library standard.
         */
        if (signer != owner()) {
            return SIG_VALIDATION_FAILED; // 1
        } else {
            return SIG_VALIDATION_SUCCESS; // 0
        }
    }

    /**
     * @param missingAccountFunds Is the max amount of gas value in Eth that the Entrypoint contract needs
     * from this contract wallet in order to pay for the user operation (txn)
     */
    function _payPrefund(uint256 missingAccountFunds) internal {
        // if gas is required (i.e if missingAccountFunds has value > 0)
        if (missingAccountFunds != 0) {
            // msg.sender is always the entryPoint contract
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            (success);
        }
    }

    // == GETTERS == //
    function getEntryPoint() public view returns (IEntryPoint) {
        return I_ENTRY_POINT;
    }
}
