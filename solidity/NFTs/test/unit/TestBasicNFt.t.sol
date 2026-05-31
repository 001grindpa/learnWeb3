// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {Test} from "../../lib/forge-std/src/Test.sol";
import {DeployBasicNFT} from "../../script/DeployBasicNFT.s.sol";
import {BasicNFT} from "../../src/BasicNFT.sol";

contract TestBasicNFT is Test {
    // declare deployer and deplyed contract variables
    BasicNFT basicNft;
    DeployBasicNFT deployer;
    address public USER = makeAddr("user");
    string public constant URI = "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";
    
    /**
    @dev this function auto runs like a special function during compilation
    @notice it is used to deploy our testing contract
     */
    function setUp() public {
        deployer = new DeployBasicNFT();
        basicNft = deployer.run();
    }

    function testNameIsCorrect() public view {
        string memory expectedName = "Basic NFT";
        string memory receivedName = basicNft.name();

        assertEq(keccak256(abi.encodePacked(expectedName)), keccak256(abi.encodePacked(receivedName)));
    }

    function testCanMintAndHaveBalance() public {
        vm.prank(USER);
        basicNft.mintNft(URI);

        assertEq(basicNft.balanceOf(USER), 1);
        assertEq(keccak256(abi.encodePacked(URI)), keccak256(abi.encodePacked(basicNft.tokenURI(1))));
    }
}