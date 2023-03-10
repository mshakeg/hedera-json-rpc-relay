// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorageIncreaser {
    uint256[] public dummyData;

    function increaseStorage(uint256 numSpaces) public {
        for (uint256 i = 0; i < numSpaces; i++) {
            dummyData.push(i);
        }
    }

    function removeLastNElements(uint256 n) public {
        require(n <= dummyData.length, 'Invalid input');

        assembly {
            // Reduce the length of the array by N elements
            let length := sload(dummyData.slot)
            sstore(dummyData.slot, sub(length, n))
        }
    }
}
