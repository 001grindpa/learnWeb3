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

    /**
    * @dev This is a intercation function, used to send the first interaction to the deployed contract
    * it sends a token approval txn calldata
     */
    function run() external {
        HelperConfig helperConfig = new HelperConfig();
        address dest = 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d;
        address smartWallet = 0xb2d42c50f27528BFaF8850cBD667D64B384bDd75;
        uint256 value = 0;
        // create txn calldata
        bytes memory functionData = 
        abi.encodeWithSelector(ERC20.approve.selector, smartWallet, 1e18);
        // create execute function calldata
        bytes memory executeCallData = 
        abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);

        PackedUserOperation memory packedUserOp = generateSignedUserOperation(
            executeCallData, helperConfig.getConfig(), smartWallet
            );
        PackedUserOperation[] memory op = new PackedUserOperation[](1);
        op[0] = packedUserOp;

        vm.startBroadcast();
        IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(
            op, payable(smartWallet) // .account repays the bundler for us
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
        // since this is a interactions script (for sending the first deployed contract intercation), the generated nonce returned
        // will be 1 but we set it to 0 by substracting 1 from it, since Nonces are zero indexed.
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
