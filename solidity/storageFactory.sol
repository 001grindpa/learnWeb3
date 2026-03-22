// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
import {SimpleStorage} from "./simpleStorage.sol";

contract StorageFactory{
    SimpleStorage[] public listOfSimpleStorages;
    struct SSDataType {
        uint256 day;
        SimpleStorage CA;
    }
    mapping(uint256 day => SimpleStorage CA) public SSObject;

    function deploySimpleStorageContract() public {
        SimpleStorage newSimpleStorage = new SimpleStorage();
        listOfSimpleStorages.push(newSimpleStorage);
    }

    function storeSimpleStorageContractListInObject() public {
        for (uint256 i=0; i < listOfSimpleStorages.length; i++) {
            SSObject[i+1] = listOfSimpleStorages[i];
        }
    }

    function setFavNumInContract(uint256 index, uint8 fav) public {
        listOfSimpleStorages[index].storeFavoriteNum(fav);
    }

    function getSimpleStorageFavNumbFromList(uint256 listIndex) public view returns(uint8) {
        SimpleStorage simpleStorageContract = listOfSimpleStorages[listIndex];
        return simpleStorageContract.retrieve();
    }
}