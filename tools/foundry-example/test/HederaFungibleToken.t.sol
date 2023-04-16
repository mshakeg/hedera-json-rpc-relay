// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./mocks/HederaFungibleToken.sol";
import "./mocks/HtsPrecompileMock.sol";

contract HederaFungibleTokenTest is Test {

    address constant htsPrecompileAddress = address(0x167);

    HtsPrecompileMock htsPrecompile = HtsPrecompileMock(htsPrecompileAddress);

    // setUp is executed before each and every test function
    function setUp() public {
        HtsPrecompileMock htsPrecompileMock = new HtsPrecompileMock();
        bytes memory code = address(htsPrecompileMock).code;
        vm.etch(htsPrecompileAddress, code);
    }

    // positive cases
    function test_CreateHederaFungibleTokenViaHtsPrecompile() public {
        (, bool isToken) = htsPrecompile.isToken(address(0x123));
        assertTrue(isToken == false);
    }

    function test_CreateHederaFungibleTokenDirectly() public {
    }

    function test_ApproveViaHtsPrecompile() public {
    }

    function test_ApproveDirectly() public {
    }

    function test_TransferViaHtsPrecompile() public {
    }

    function test_TransferDirectly() public {
    }

    // negative cases
    function test_CannotApproveIfSpenderNotAssociated() public {
        // cannot approve spender if spender is not associated with HederaFungibleToken BOTH directly and viaHtsPrecompile
    }

    function test_CannotTransferIfRecipientNotAssociated() public {
        // cannot transfer to recipient if recipient is not associated with HederaFungibleToken BOTH directly and viaHtsPrecompile
    }

}
