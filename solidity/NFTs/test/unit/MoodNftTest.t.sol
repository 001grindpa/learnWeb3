// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {MoodNFT} from "../../src/MoodNFT.sol";
import {DeployMoodNFT} from "../../script/DeployMoodNFT.s.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MoodNftTest is Test {
    MoodNFT moodNft;
    string public constant SAD_FACE_SVG_URI = "data:image/svg+xml; base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgdmlld0JveD0iMCAwIDIwMCAyMDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CiAgPGNpcmNsZSBjeD0iMTAwIiBjeT0iMTAwIiByPSI4MCIgZmlsbD0iI0ZGRDcwMCIgc3Ryb2tlPSIjMDAwMDAwIiBzdHJva2Utd2lkdGg9IjMiLz4KICAKICA8Y2lyY2xlIGN4PSI3MCIgY3k9IjgwIiByPSIxMCIgZmlsbD0iIzAwMDAwMCIvPgogIDxjaXJjbGUgY3g9IjEzMCIgY3k9IjgwIiByPSIxMCIgZmlsbD0iIzAwMDAwMCIvPgogIAogIDxjaXJjbGUgY3g9IjcwIiBjeT0iODAiIHI9IjQiIGZpbGw9IiNGRkZGRkYiLz4KICA8Y2lyY2xlIGN4PSIxMzAiIGN5PSI4MCIgcj0iNCIgZmlsbD0iI0ZGRkZGRiIvPgoKICA8cGF0aCBkPSJNIDU1IDYwIFEgNzAgNTAgODUgNjAiIGZpbGw9Im5vbmUiIHN0cm9rZT0iIzAwMDAwMCIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiLz4KICA8cGF0aCBkPSJNIDExNSA2MCBRIDEzMCA1MCAxNDUgNjAiIGZpbGw9Im5vbmUiIHN0cm9rZT0iIzAwMDAwMCIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiLz4KICAKICA8cGF0aCBkPSJNIDYwIDE0MCBRIDEwMCAxMTAgMTQwIDE0MCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjMDAwMDAwIiBzdHJva2Utd2lkdGg9IjMiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgo8L3N2Zz4=";
    string public constant HAPPY_FACE_SVG_URI = "data:image/svg+xml; base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgdmlld0JveD0iMCAwIDIwMCAyMDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CiAgPGNpcmNsZSBjeD0iMTAwIiBjeT0iMTAwIiByPSI4MCIgZmlsbD0iI0ZGRDcwMCIgc3Ryb2tlPSIjMDAwMDAwIiBzdHJva2Utd2lkdGg9IjMiLz4KICAKICA8Y2lyY2xlIGN4PSI3MCIgY3k9IjgwIiByPSIxMCIgZmlsbD0iIzAwMDAwMCIvPgogIDxjaXJjbGUgY3g9IjEzMCIgY3k9IjgwIiByPSIxMCIgZmlsbD0iIzAwMDAwMCIvPgogIAogIDxjaXJjbGUgY3g9IjcwIiBjeT0iODAiIHI9IjQiIGZpbGw9IiNGRkZGRkYiLz4KICA8Y2lyY2xlIGN4PSIxMzAiIGN5PSI4MCIgcj0iNCIgZmlsbD0iI0ZGRkZGRiIvPgogIAogIDxwYXRoIGQ9Ik0gNjAgMTMwIFEgMTAwIDE2MCAxNDAgMTMwIiBmaWxsPSJub25lIiBzdHJva2U9IiMwMDAwMDAiIHN0cm9rZS13aWR0aD0iMyIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIi8+Cjwvc3ZnPg==";
    address public USER = makeAddr("user");

    function setUp() external {
        moodNft = new MoodNFT(SAD_FACE_SVG_URI, HAPPY_FACE_SVG_URI);
    }

    function testViewTokenURI() public {
        if (block.chainid == 11155111) {
            return;
        }
        vm.prank(USER);
        moodNft.mintNFT();
        console.log(moodNft.tokenURI(1));
    }
}

// integration test
