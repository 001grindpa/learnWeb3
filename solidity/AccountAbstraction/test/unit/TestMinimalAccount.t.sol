// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {MinimalAccount} from "../../src/MinimalAccount.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployMinimalAccount} from "../../script/DeployMinimalAccount.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
// import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SendPackedUserOp, PackedUserOperation} from "../../script/SendPackedUserOp.s.sol";
// PackedUserOperation is already imported in SendPackedUserOp contract,
// we'll just re-route the importation here from SendPackedUserOp
import {IEntryPoint} from "../../lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract TestMinimalAccount is Test {
    using MessageHashUtils for bytes32;

    MinimalAccount minimalAccount;
    HelperConfig helperConfig;
    DeployMinimalAccount deployer;
    address entryPoint;
    address public user = makeAddr("user");
    ERC20Mock usdc;
    uint256 constant TEST_AMOUNT = 5e18; // 5 tokens
    SendPackedUserOp sendPackedUserOp;
    HelperConfig.NetworkConfig config;

    function setUp() external {
        deployer = new DeployMinimalAccount();
        (minimalAccount, helperConfig) = deployer.run();
        config = helperConfig.getConfig();
        entryPoint = config.entryPoint;

        vm.deal(user, 5e18);
        // deploy erc20 token mock
        usdc = new ERC20Mock();
        // instanciate the sendPackedUserOp contracts
        sendPackedUserOp = new SendPackedUserOp();
    }

    /**
     * @dev This test function also calculates gas used(which is unneccesary)
     * @notice This test function checks if the smart wallet deployer can call
     * the execute function in the smart wallet
     */
    function testOwnerCanExecuteCommands() public {
        // check mock erc20 token balance in minimalAccount smart wallet before minting tokens to it
        console.log(usdc.balanceOf(address(minimalAccount)));

        address dest = address(usdc);
        // since we're not sending eth to the mock erc20 contract
        uint256 value = 0;
        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), TEST_AMOUNT);

        vm.txGasPrice(1 gwei);
        console.log("Gas price: ", tx.gasprice);
        uint256 gasStart = gasleft();
        vm.prank(minimalAccount.owner());
        minimalAccount.execute(dest, value, functionData);
        uint256 gasUsed = gasStart - gasleft();
        console.log("Gas used: ", gasUsed);
        uint256 gasCost = gasUsed * tx.gasprice;
        console.log("Gas cost: ", gasCost);

        // check mock erc20 token balance in minimalAccount smart wallet afterwards
        // console.log(usdc.balanceOf(address(minimalAccount)));
        assert(usdc.balanceOf(address(minimalAccount)) == TEST_AMOUNT);
    }

    /**
     * @notice This function tests if minimal account reverts when an address
     * that is not either the Entry point contract or EOA address tries to call
     * it's execute function
     */
    function testNonOwnerCanNotRunExecuteFunction() public {
        address dest = address(usdc);
        // since we're not sending eth to the mock erc20 contract
        uint256 value = 0;
        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), TEST_AMOUNT);

        vm.expectRevert(
            abi.encodeWithSelector(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector, address(user))
        );
        vm.prank(user);
        minimalAccount.execute(dest, value, functionData);
    }

    /**
     * @notice This function mints mock tokens to the smart account and
     * sends some of those mock tokens to a random address
     */
    function testOwnerCanMintTokenToSmartWalletAndTransferItOut() public mintMockERC20ToMinimalAccountWallet {
        address ca = address(usdc);
        uint256 sendEth = 0;

        console.log("account2 initial token bal: ", usdc.balanceOf(address(user)));
        // send some token to a random user
        uint256 amountToSend = 2e18;
        bytes memory funcCallDataToTransfer = abi.encodeWithSelector(ERC20.transfer.selector, user, amountToSend);

        console.log("transfering %s tokens to account 2...", amountToSend / 1e18);
        vm.prank(address(minimalAccount.owner()));
        minimalAccount.execute(ca, sendEth, funcCallDataToTransfer);
        console.log("Transfer to account 2 successful");
        console.log("account2 token new token bal: %s tokens", usdc.balanceOf(address(user)) / 1e18);
        console.log(
            "minimal account new token balalnce after transfer: ", usdc.balanceOf(address(minimalAccount)) / 1e18
        );
    }

    function testRecoverSignedOp() public view {
        // use the Entry point contract to create user operation struct
        // implement a calldata that the Entry point contract uses to
        // call the execute function in the smart wallet in a low level way
        // this calldata will become the calldata attribute of the user operation struct
        // the calldata will contain code that tries to mint mock tokens to the
        // smart wallet but will need a signed txn from the smart wallet to do this
        // however since this test is only used to check if signing is actually working
        // i.e if the signature gotten using message standard hash is actually returning
        // the signer's address after recovery, the code doesn't actually get to the point
        // where token is minted.
        bytes memory mintCallData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), TEST_AMOUNT);

        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(mintCallData, config, address(minimalAccount));
        // convert packedUserOp to it's hash form
        // the EntryPoint contract has a function that hashes the userOp struct (txn message) without including the
        // signature attribute
        bytes32 packedUserOpHash = IEntryPoint(entryPoint).getUserOpHash(packedUserOp);

        // use syntactic suger to convert packedUserOpHash to a standard message hash using MessageHashUtils library
        bytes32 standardPackedUserOpHash = packedUserOpHash.toEthSignedMessageHash();

        // the recover function from the ECDSA library, recovers the public key from the standardPackedUserOpHash and signature
        // and returns the encoded signer(wallet address) from the last 20bytes of that recovered public key hash
        address signer = ECDSA.recover(standardPackedUserOpHash, packedUserOp.signature);

        console.log("signer: %s\nactual owner: %s", signer, minimalAccount.owner());
        assert(signer == minimalAccount.owner());
    }

    function testValidationOfUserOps() public {
        bytes memory mintCallData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), TEST_AMOUNT);

        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(mintCallData, config, address(minimalAccount));
        // convert packedUserOp to it's hash form
        // the EntryPoint contract has a function that hashes the userOp struct without including the
        // signature attribute
        bytes32 packedUserOpHash = IEntryPoint(entryPoint).getUserOpHash(packedUserOp);
        uint256 missingAccountFunds = 1e18;

        // use the entry point contract to send packedUserOp struct (txn message) and packedUserOpHash (it's hash)
        // inside this validateUserOp function in the smart wallet contract, we know that if this function returns
        // 1, it means the validation did not work, if it returns 0 it did
        vm.prank(entryPoint);
        uint256 validationData = minimalAccount.validateUserOp(packedUserOp, packedUserOpHash, missingAccountFunds);
        // use assert to check if it passed, i.e returned 0
        assert(validationData == 0);
    }

    /**
     * @notice This function allows Entry point contract to create user operation struct from the submitted user operation
     * given to it by the bundler, after verfying the smart wallet signature, it then mints a mock erc20 token to the
     * smart wallet by calling the smart wallet's execute function
     */
    function testEntryPointCanExecuteCommands() public {
        address tokenContractAddy = address(usdc);
        uint256 ethToSend = 0;
        // because the entry point wants to call the execute function of our smart wallet, it'll need a signature approval
        // after the signature is validated then the execute funtion is called successfully
        // for this case, the entry point wants to mint mock tokens to the smart wallet via the execute function.
        bytes memory mintCallData = 
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), TEST_AMOUNT);
        // inside the execute call-data itself we'll need to pass the call-data of the token minting txn
        bytes memory executeCallData =
            abi.encodeWithSelector(MinimalAccount.execute.selector, tokenContractAddy, ethToSend, mintCallData);

        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(executeCallData, config, address(minimalAccount));
        // during execution, the entry point calls the function who's selector is passed in executeCallData, it passes the provided arguments to it
        // and runs it automatically

        // fund the smart wallet with ether using vm.deal() cheatcode
        vm.deal(address(minimalAccount), 6e18);
        console.log("Smart wallet eth bal: %s ether", address(minimalAccount).balance / 1e18);

        // create a random user which will act like our bundler here.
        address bundler = makeAddr("bundler");
        vm.deal(bundler, 100e18);
        // When the Entry point's handleOp() function is called, it takes the caller's address (bundler)
        // as second argument so that it will resend the used gas back to that address when it's recieved from the smart wallet

        // ops is expected to be an array of all user operations in the alt mem pool, sent by bundler. since we're
        // only passing one userOp, we'll create a static array of user operations with a size of one and fill in
        // our user operation in that el position
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;
        vm.startPrank(bundler, bundler); // prank/call with bundler
        IEntryPoint(entryPoint).handleOps(ops, payable(bundler));
        vm.stopPrank();

        console.log(usdc.balanceOf(address(minimalAccount)));
    }

    // ==== MODIFIERS === //
    modifier mintMockERC20ToMinimalAccountWallet() {
        address usdContractAddy = address(usdc);
        uint256 amountToMint = 6e18; // 6 mock tokens
        uint256 sendEth = 0; // the execute function does not need to send eth to msg.sender
        bytes memory mintToMinimalCallData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), amountToMint);

        vm.prank(minimalAccount.owner());
        console.log("minting %s mock tokens...", amountToMint / 1e18);
        minimalAccount.execute(usdContractAddy, sendEth, mintToMinimalCallData);
        console.log("%s ERC20 tokens minted", amountToMint / 1e18);
        console.log("minimal account token bal: %s tokens", usdc.balanceOf(address(minimalAccount)) / 1e18);
        _;
    }
}
