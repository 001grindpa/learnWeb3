// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
* @author 0xgrindpa
* @dev This is the initial contract which will be later upgraded to a version2
* @notice It will implement a couple of abstract functions inherited from UUPSUpgradeable parent
*/
contract BoxV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 internal number;

    /**
    * @dev initializer is a modifier from the Initializable parent contract
    * it makes sure the initialize() function is autocalled during deployment
    * and not called again after that.
    * @notice This function runs like a constructor since proxie contracts do 
    * not use conventional constructors.
    * @notice __Ownable_init() is a function from OwnableUpgradeable() parent 
    * contract that sets the deployer address as owner to a storage variable
    * it has a dunder because it's an initializer function (i.e only called 
    * inside the initializer)
     */
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function getNumber() external view returns (uint256) {
        return number;
    }

    function version() external pure returns (uint256) {
        return 1;
    }
 
    /** 
    * @dev When implemented:
    * This function is supposed to revert an error when an unauthorized/random user
    * tries to upgrade the contract. Keeping it empty means you want anybody to be able 
    * to upgrade the contract i.e change the logic/implementation contract address
    */ 
    function _authorizeUpgrade(address newImplementation) internal overide {}
}
