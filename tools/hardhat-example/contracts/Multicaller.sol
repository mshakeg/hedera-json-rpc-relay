//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./base/Multicall.sol";

contract Multicaller is Multicall {

    event ShortInput(uint a);

    function processShortInput(uint a) pure external returns (uint double) {
        double = a*2;
    }

    function processLongInput(uint a, uint b, uint c, uint d, uint e, uint f, uint g) pure external returns (uint sum) {
        // commented out to reduce gas cost
        // sum = a + b + c + d + e + f + g;
    }

    struct VeryLongInput {
        uint a;
        uint b;
        uint c;
        uint d;

        uint e;
        uint f;
        uint g;
        uint h;

        uint i;
        uint j;
        uint k;
        uint l;

        uint m;
        uint n;
        uint o;
    }

    function processVeryLongInput(VeryLongInput memory veryLongInput) pure external returns (uint sum) {
        // commented out to reduce gas cost
        // sum =
        //     veryLongInput.a +
        //     veryLongInput.b +
        //     veryLongInput.c +
        //     veryLongInput.d +
        //     veryLongInput.e +
        //     veryLongInput.f +
        //     veryLongInput.g +
        //     veryLongInput.h +
        //     veryLongInput.i +
        //     veryLongInput.j +
        //     veryLongInput.k +
        //     veryLongInput.l +
        //     veryLongInput.m +
        //     veryLongInput.n +
        //     veryLongInput.o;
    }
}
