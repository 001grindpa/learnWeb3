// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IEntryPoint} from "../lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {MinimalAccount} from "../src/MinimalAccount.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract SendPackedUserOp is Script {
    using MessageHashUtils for bytes32;

    function run() external {
        HelperConfig helperConfig = new HelperConfig();
        address dest = hex""; // insert the arbitrum usdc sepolia ca here
        address smartWallet = hex""; // insert your deployed smart wallet ca here
        uint256 value = 0;
        bytes memory functionData = 
        abi.encodeWithSelector(IERC20.approve.selector, smartWallet, 1e18);
        bytes memory executeCallData = 
        abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);

        PackedUserOperation memory packedUserOp = generateSignedUserOperation(
            executeCallData, helperConfig.getConfig(), smartWallet
            );
        PackedUserOperation[] memory op = new PackedUserOperation[](1);
        op[0] = packedUserOp;
        vm.startBroadcast();
        IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(
            op, payable(helperConfig.getAnvilConfig().account) // .account repays the bundler for us
            ); // .account can be a paymaster etc
        vm.stopBroadcast();
        // go to helper config and add a config option for arbitrum
    }

    /**
     * @notice This function takes the txn message(user operation struct details) and
     * generates a hash with it, then uses that message hash to generate a 65 byte signature hash
     */
    function generateSignedUserOperation(
        bytes memory callData,
        HelperConfig.NetworkConfig memory config,
        address minimalAccount
    ) public view returns (PackedUserOperation memory) {
        // 1. Generate the unsigned data
        uint256 nonce = vm.getNonce(minimalAccount) - 1;
        PackedUserOperation memory unsignedUserOp = _generateUnsignedUserOperation(callData, minimalAccount, nonce);

        // 2. Get the userOp Hash
        // this is the txn message bytes form
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(unsignedUserOp);

        // 3. Sign it, and return it
        // we'll generate a standard message hash with that message byte from
        // MessageHashUtils library contains a function (toEthSignedMessageHash()) used in generating a EIP-191
        // 32 byte message hash by wrapping the message byte form together with "\19xEthereum Signed Message:\n32"
        // remember digest is just a data hash
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        // 4. Now we'll take this EIP-191 standard message hash and generate a 65 byte signature with it.
        // since the we do not have access to a unlocked account private key when we try to run this code
        // with a test contract (on anvil). we will use the default sender's default pk here to sign the txn
        uint8 v;
        bytes32 r;
        bytes32 s;
        if (block.chainid == 31337) {
            uint256 DEFAULT_PK = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
            // sign with exposed anvil key
            (v, r, s) = vm.sign(DEFAULT_PK, digest);
        } else {
            // if chain is not anvil
            // to the right is the 65 byte message signature, to the left is the components of that signature (v, r, s)
            (v, r, s) = vm.sign(config.account, digest);
        }
        // these three componets are hashed together and used to overide the unsignedUserOp struct's signature attribute
        // thereby making it signed
        unsignedUserOp.signature = abi.encodePacked(r, s, v); // Notice the order
        return unsignedUserOp; // now signed
    }

    /**
     * @notice this function generates the txn message (user operation struct)
     * @param _sender This arg belongs to the smart wallet and not the EOA wallet
     */
    function _generateUnsignedUserOperation(bytes memory _callData, address _sender, uint256 _nonce)
        internal
        pure
        returns (PackedUserOperation memory)
    {
        // deciding what priority and base fee you want to spend is usually done manualy in
        // a regulat wallet before sending the txn, but those parameters are hardcoded for
        // a smart wallet user operation
        uint128 verificationGasLimit = 16777216; // max gas the smart wallet is willing to repay
        // during userop validation
        uint128 callGasLimit = verificationGasLimit;

        uint128 maxPriorityFeePerGas = 256; // wei value per gas
        uint128 maxFeePerGas = maxPriorityFeePerGas;

        // Alot of these properties are kept blank because this smart wallet is for study illustration
        return PackedUserOperation({
            sender: _sender,
            nonce: _nonce,
            initCode: hex"",
            callData: _callData,
            accountGasLimits: bytes32((uint256(verificationGasLimit) << 128) | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32((uint256(maxPriorityFeePerGas) << 128) | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}
