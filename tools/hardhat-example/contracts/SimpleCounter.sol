//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// this contract has an associated test script that generates as many txs as possible
// this could be useful to fill blocks with as many txs as possible
contract SimpleCounter {
    uint256 count;

    function increment() public {
        count++;
    }

    function getCount() public view returns (uint256) {
        return count;
    }
}
