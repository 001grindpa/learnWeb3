// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MoodNFT is ERC721 {
    // custom error
    error MoodNFT__NeitherOwnerNorApproved(address sender);

    // events
    event NftMoodFlipped(uint256 indexed tokenId, address indexed wallet, MoodNFT_Mood state);

    /** custom datatype declarations */
    
    // state variables
    uint256 private sTokenCounter;
    string private sSadSvgURI;
    string private sHappySvgURI;
    enum MoodNFT_Mood {
        HAPPY,
        SAD
    }
    mapping(uint256 id => string uri) public sIdToUriMap;
    mapping(uint256 tokenId => MoodNFT_Mood nftMood) private sTokenIdToMoodMap;

    constructor(string memory sadSvg, string memory happySvg)
     ERC721("Mood NFT", "MNFT") {
        sTokenCounter = 1;
        sSadSvgURI = sadSvg;
        sHappySvgURI = happySvg;
    }

    function _baseURI() internal pure override returns(string memory) {
        // we're converting a json object to base64 string not image
        return "data:application/json;base64,";
    }

    /**
    @dev this function sets the mood of newly minted NFTs to Happy by default
    @notice the mood state variable is declared as/in sTokenIdToMoodMap property value 
     */
    function mintNFT() public {
        // sIdToUriMap[sTokenCounter] = uri;
        sTokenIdToMoodMap[sTokenCounter] = MoodNFT_Mood.HAPPY;
        // _mint(msg.sender, sTokenCounter);
        _safeMint(msg.sender, sTokenCounter);
        sTokenCounter++;
    }

    function getSvgMoodWithTokenId(uint256 tokenId) public view returns (MoodNFT_Mood) {
        return sTokenIdToMoodMap[tokenId];
    }

    function flipMood(uint256 tokenId) public {
        if (!_isAuthorized((_ownerOf(tokenId)), msg.sender, tokenId)) {revert MoodNFT__NeitherOwnerNorApproved(msg.sender);}
        if (sTokenIdToMoodMap[tokenId] == MoodNFT_Mood.HAPPY) {
            sTokenIdToMoodMap[tokenId] = MoodNFT_Mood.SAD;
        } else {
            sTokenIdToMoodMap[tokenId] = MoodNFT_Mood.HAPPY;
        }
        emit NftMoodFlipped(tokenId, msg.sender, sTokenIdToMoodMap[tokenId]);
    }

    /**
    @notice concatenated variables is passed as ', variable,' in a single quoted string or 
    ", varaible," if it is a double quoted string inside string.concate() method. or abi.encodePacked()
     */
    function tokenURI(/*string memory imageUri */uint256 tokenId) public view override returns (string memory) {
        string memory sImageURI;
        // choose image uri based on contract state
        if (sTokenIdToMoodMap[tokenId] == MoodNFT_Mood.HAPPY) {
            sImageURI = sHappySvgURI;
        } else {
            sImageURI = sSadSvgURI;
        }
        // use double quotes for your json property key/value. json standards strictly require this
        string memory tokenMetaData = string.concat(
            '{"name": "', name(),'", "description": "An NFT that reflects the owners mood", "attributes": [{"trait_type": "moodiness", "value": 100}], "image": "', sImageURI,'"}'
        );
        
        // typecast the encodeJSONString to bytes
        // this is how we can use the Openzeppelin base64 util to covert the encodedString bytes
        // to it's base64 string representation
        bytes memory encodedString = bytes(abi.encodePacked(tokenMetaData));

        // convert the encodedString byte to base64 string
        // type cast it as string
        string memory base64String = string(Base64.encode(encodedString));
        
        string memory uriUsingBase64String = string(
            abi.encodePacked(
                _baseURI(),
                base64String
            )
        );
        return uriUsingBase64String;
    }
}