// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {MoodNFT} from "../../src/MoodNFT.sol";
import {DeployMoodNFT} from "../../script/DeployMoodNFT.s.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MoodNftIntegrationsTest is Test {
    DeployMoodNFT public deployer;
    MoodNFT public moodNft;
    address USER = makeAddr("user");
    // the sad_svg_url's base64 is wrong due to possible white 
    // space in the json script you got it from
    string SAD_SVG_URI = "data:application/json;base64,InsnbmFtZSc6ICdNb29kIE5GVCcsICdkZXNjcmlwdGlvbic6ICdBbiBORlQgdGhhdCByZWZsZWN0cyB0aGUgb3duZXIncyBtb29kJywgJ2F0dHJpYnV0ZXMnOiBbeyd0cmFpdF90eXBlJzogJ21vb2RpbmVzcycsICd2YWx1ZSc6IDEwMH1dLCAnaW1hZ2UnOiAnZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpTWpBd0lpQm9aV2xuYUhROUlqSXdNQ0lnZG1sbGQwSnZlRDBpTUNBd0lESXdNQ0F5TURBaUlIaHRiRzV6UFNKb2RIUndPaTh2ZDNkM0xuY3pMbTl5Wnk4eU1EQXdMM04yWnlJK0NpQWdQR05wY21Oc1pTQmplRDBpTVRBd0lpQmplVDBpTVRBd0lpQnlQU0k0TUNJZ1ptbHNiRDBpSTBaR1JEY3dNQ0lnYzNSeWIydGxQU0lqTURBd01EQXdJaUJ6ZEhKdmEyVXRkMmxrZEdnOUlqTWlMejRLSUNBS0lDQThZMmx5WTJ4bElHTjRQU0kzTUNJZ1kzazlJamd3SWlCeVBTSXhNQ0lnWm1sc2JEMGlJekF3TURBd01DSXZQZ29nSUR4amFYSmpiR1VnWTNnOUlqRXpNQ0lnWTNrOUlqZ3dJaUJ5UFNJeE1DSWdabWxzYkQwaUl6QXdNREF3TUNJdlBnb2dJQW9nSUR4amFYSmpiR1VnWTNnOUlqY3dJaUJqZVQwaU9EQWlJSEk5SWpRaUlHWnBiR3c5SWlOR1JrWkdSa1lpTHo0S0lDQThZMmx5WTJ4bElHTjRQU0l4TXpBaUlHTjVQU0k0TUNJZ2NqMGlOQ0lnWm1sc2JEMGlJMFpHUmtaR1JpSXZQZ29LSUNBOGNHRjBhQ0JrUFNKTklEVTFJRFl3SUZFZ056QWdOVEFnT0RVZ05qQWlJR1pwYkd3OUltNXZibVVpSUhOMGNtOXJaVDBpSXpBd01EQXdNQ0lnYzNSeWIydGxMWGRwWkhSb1BTSXlJaUJ6ZEhKdmEyVXRiR2x1WldOaGNEMGljbTkxYm1RaUx6NEtJQ0E4Y0dGMGFDQmtQU0pOSURFeE5TQTJNQ0JSSURFek1DQTFNQ0F4TkRVZ05qQWlJR1pwYkd3OUltNXZibVVpSUhOMGNtOXJaVDBpSXpBd01EQXdNQ0lnYzNSeWIydGxMWGRwWkhSb1BTSXlJaUJ6ZEhKdmEyVXRiR2x1WldOaGNEMGljbTkxYm1RaUx6NEtJQ0FLSUNBOGNHRjBhQ0JrUFNKTklEWXdJREUwTUNCUklERXdNQ0F4TVRBZ01UUXdJREUwTUNJZ1ptbHNiRDBpYm05dVpTSWdjM1J5YjJ0bFBTSWpNREF3TURBd0lpQnpkSEp2YTJVdGQybGtkR2c5SWpNaUlITjBjbTlyWlMxc2FXNWxZMkZ3UFNKeWIzVnVaQ0l2UGdvOEwzTjJaejQ9J30i";

    function setUp() external returns (MoodNFT) {
        deployer = new DeployMoodNFT();
        moodNft = deployer.run();
        return moodNft;
        // return deployer;
    }

    function testReturnedSvgUriIsCorrect() public view {
        string memory expectedUri = "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI1MDAiIGhlaWdodD0iNTAwIj48dGV4dCB4PSIwIiB5PSIxNSIgZmlsbD0id2hpdGUiPmhpLCB5b3UgZGVjb2RlZCB0aGlzIHN2ZyE8L3RleHQ+PHRleHQgeD0iMCIgeT0iMzUiIGZpbGw9InJlZCI+eWVsbG93IGNpcmNsZSBiZWxvdzwvdGV4dD48Y2lyY2xlIGN4PSI1MCIgY3k9IjkwIiByPSI0MCIgZmlsbD0ieWVsbG93IiAvPjwvc3ZnPg==";
        string memory svgCode = '<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500"><text x="0" y="15" fill="white">hi, you decoded this svg!</text><text x="0" y="35" fill="red">yellow circle below</text><circle cx="50" cy="90" r="40" fill="yellow" /></svg>';
        // the svgCodeToSvgURI function is declared in the deployer script not the MoodNft contract
        string memory actualUri = deployer.svgCodeToSvgURI(svgCode);
        
        assert(keccak256(abi.encodePacked(expectedUri)) == keccak256(abi.encodePacked(actualUri)));
    }

    function testIfBase64IsMatching() public view {
        string memory expectedBase64 = "PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI1MDAiIGhlaWdodD0iNTAwIj48dGV4dCB4PSIwIiB5PSIxNSIgZmlsbD0id2hpdGUiPmhpLCB5b3UgZGVjb2RlZCB0aGlzIHN2ZyE8L3RleHQ+PHRleHQgeD0iMCIgeT0iMzUiIGZpbGw9InJlZCI+eWVsbG93IGNpcmNsZSBiZWxvdzwvdGV4dD48Y2lyY2xlIGN4PSI1MCIgY3k9IjkwIiByPSI0MCIgZmlsbD0ieWVsbG93IiAvPjwvc3ZnPg==";
       
        string memory svgCode = '<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500"><text x="0" y="15" fill="white">hi, you decoded this svg!</text><text x="0" y="35" fill="red">yellow circle below</text><circle cx="50" cy="90" r="40" fill="yellow" /></svg>';
        // the svgCodeToSvgURI function is declared in the deployer script not the MoodNft contract
        string memory actualBase64 = deployer.getBase64String(svgCode);
        console.log("ACTUAL BASE64 STRING: %s", actualBase64);
        console.log("\nEXPECTED BASE64 STRING: %s", expectedBase64);

        assert(keccak256(abi.encodePacked(expectedBase64)) == keccak256(abi.encodePacked(actualBase64)));
    }

    function testFlipTokenToSadPrintMood() public nonSepoliaTest {
        // string memory encodedSadSvgMetaData = Base64(keccak256(abi.encodePacked(SAD_SVG_METADATA)));
        vm.prank(USER);
        moodNft.mintNFT();
        // print the svg state before flipping mood
        console.log(uint256(moodNft.getSvgMoodWithTokenId(1))); // mood should be 0 (HAPPY) by default
        assert(uint256(moodNft.getSvgMoodWithTokenId(1)) == 0);
        
        // print the svg state after flipping mood
        vm.prank(USER);
        moodNft.flipMood(1); //flips mood
        console.log(uint256(moodNft.getSvgMoodWithTokenId(1))); // mood should be 1 (SAD) after flipping
        assert(uint256(moodNft.getSvgMoodWithTokenId(1)) == 1);
    }

     function testFlipTokenToSadPrintMetaData() public {
        vm.prank(USER);
        moodNft.mintNFT();
        console.log("HAPPY MOOD SVG METADATA: %s", moodNft.tokenURI(1)); // this uri should return metadata with smilyface svg as image by default

        // let's flip the NFT/svg mood
        vm.prank(USER);
        moodNft.flipMood(1);
        console.log("SAD MOOD SVG METADATA: %s", moodNft.tokenURI(1)); // this uri should now return metadata with the sadFace svg version 
    }

    modifier nonSepoliaTest {
        if (block.chainid == 11155111) {
            return;
        }
        _;
    }
}