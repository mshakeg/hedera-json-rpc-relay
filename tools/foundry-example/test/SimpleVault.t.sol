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
    function test_Deposit() public {
    }

    function test_Withdraw() public {
    }

    function test_DepositAndWithdraw() public {
    }

    // negative cases:
    function test_CannotDepositIfNotAssociated() public {
    }

    function test_CannotWithdrawIfNotAssociated() public {
    }
}
