// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SimpleVault.sol";

contract SimpleVaultTest is Test {
    SimpleVault public simpleVault;

    // setUp is executed before each and every test function
    function setUp() public {
        simpleVault = new SimpleVault();
        // create 2 tokens here
        // associate vault with 2 tokens
    }

    // positive cases:
    function testDeposit() public {
    }

    function testWithdraw() public {
    }

    function testDepositAndWithdraw() public {
    }

    // negative cases:
    function testCannotDepositIfNotAssociated() public {
    }

    function testCannotWithdrawIfNotAssociated() public {
    }
}
