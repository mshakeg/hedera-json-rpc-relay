// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import 'hedera-smart-contracts/hts-precompile/IHederaTokenService.sol';
import 'hedera-smart-contracts/hts-precompile/HederaResponseCodes.sol';
import "./mocks/HederaFungibleToken.sol";
import "./mocks/HtsPrecompileMock.sol";

contract HederaFungibleTokenTest is Test {

    address alice = vm.addr(1);
    address bob = vm.addr(2);
    address carol = vm.addr(3);
    address dave = vm.addr(4);

    address constant htsPrecompileAddress = address(0x167);

    HtsPrecompileMock htsPrecompile = HtsPrecompileMock(htsPrecompileAddress);

    // setUp is executed before each and every test function
    function setUp() public {
        HtsPrecompileMock htsPrecompileMock = new HtsPrecompileMock();
        bytes memory code = address(htsPrecompileMock).code;
        vm.etch(htsPrecompileAddress, code);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(carol, 100 ether);
        vm.deal(dave, 100 ether);
    }

    // positive cases
    function test_CreateHederaFungibleTokenViaHtsPrecompile() public {
        vm.startPrank(alice);
        (, bool isToken) = htsPrecompile.isToken(address(0x123));
        assertTrue(isToken == false);
        IHederaTokenService.HederaToken memory token;
        token.name = "Token A";
        token.symbol = "TA";
        token.treasury = alice;
        int64 initialTotalSupply = 1e16;
        int32 decimals = 8;
        (int64 responseCode, address tokenAddress) = htsPrecompile.createFungibleToken(token, initialTotalSupply, decimals);

        assertEq(responseCode, HederaResponseCodes.SUCCESS, "Failed to createFungibleToken");
        HederaFungibleToken hederaFungibleToken = HederaFungibleToken(tokenAddress);

        assertEq(uint64(initialTotalSupply), hederaFungibleToken.totalSupply(), "Did not set initial supply correctly");
        assertEq(token.name, hederaFungibleToken.name(), "Did not set name correctly");
        assertEq(token.symbol, hederaFungibleToken.symbol(), "Did not set symbol correctly");
        assertEq(hederaFungibleToken.totalSupply(), hederaFungibleToken.balanceOf(token.treasury), "Did not mint initial supply to treasury");

        vm.stopPrank();
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
