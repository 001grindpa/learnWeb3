// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BasicNFT is ERC721 {
    uint256 private sTokenCounter;
    mapping(uint256 tokenId => string URI) public idToUriMap;

    constructor()ERC721("Basic NFT", "BNFT") {
        sTokenCounter = 1;
    }

    function mintNft(string memory uri) public {
        idToUriMap[sTokenCounter] = uri;
        _mint(msg.sender, sTokenCounter);
        sTokenCounter++;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return idToUriMap[tokenId];
    }
}

// "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json"
// ipfs://QmawSrPbMJ8ptqxAvLU9Yg6mZx97Akj9p4V2VRwyjLbSfr