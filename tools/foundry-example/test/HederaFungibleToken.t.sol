// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./mocks/HederaFungibleToken.sol";

contract HederaFungibleTokenTest is Test {

    // setUp is executed before each and every test function
    function setUp() public {
        // etch HtsPrecompileMock to 0x167 here
    }

    // positive cases
    function testCreateHederaFungibleTokenViaHtsPrecompile() public {
    }

    function testCreateHederaFungibleTokenDirectly() public {
    }

    function testApproveViaHtsPrecompile() public {
    }

    function testApproveDirectly() public {
    }

    function testTransferViaHtsPrecompile() public {
    }

    function testTransferDirectly() public {
    }

    // negative cases
    function testCannotApproveIfSpenderNotAssociated() public {
        // cannot approve spender if spender is not associated with HederaFungibleToken BOTH directly and viaHtsPrecompile
    }

    function testCannotTransferIfRecipientNotAssociated() public {
        // cannot transfer to recipient if recipient is not associated with HederaFungibleToken BOTH directly and viaHtsPrecompile
    }

}
