// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
* @title BoxV2
* @notice This is the upgraded logic/implementation contract,
* it will be used to replace the first version (BoxV1) for 
* the course of this test
 */
contract BoxV2 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 internal number;

    /**
    * @dev passing '_disableInitializers()' function here tells the contract never to run
    * the constructor in any case
    * @notice We already know constructors do not initialise state here,
    * however, the function call inside the constructor tells it not 
    * to ever run the constructor under any circumstances
     */
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        // __Ownable_init();
    }

    function setNumber(uint256 _number) external {
        number = _number;
    }

    function getNumber() external view returns (uint256) {
        return number + 2;
    }

    function version() external pure returns (uint256) {
        return 2;
    }

    function _authorizeUpgrade(address newImplementation) internal override {}
}
