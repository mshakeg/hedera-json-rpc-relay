// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import 'forge-std/console.sol';

import 'hedera-smart-contracts/hts-precompile/IHederaTokenService.sol';
import 'hedera-smart-contracts/hts-precompile/HederaResponseCodes.sol';
import './mocks/HederaFungibleToken.sol';
import './mocks/HtsPrecompileMock.sol';

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

    function _getSimpleHederaToken(
        string memory name,
        string memory symbol,
        address treasury
    ) internal returns (IHederaTokenService.HederaToken memory token) {
        token.name = name;
        token.symbol = symbol;
        token.treasury = treasury;
    }

    function _getSimpleHederaFungibleTokenInfo(
        string memory name,
        string memory symbol,
        address treasury,
        int64 initialTotalSupply,
        int32 decimals
    ) internal returns (IHederaTokenService.FungibleTokenInfo memory fungibleTokenInfo) {
        IHederaTokenService.TokenInfo memory tokenInfo;

        IHederaTokenService.HederaToken memory token = _getSimpleHederaToken(name, symbol, treasury);

        tokenInfo.token = token;
        tokenInfo.totalSupply = initialTotalSupply;

        fungibleTokenInfo.decimals = decimals;
        fungibleTokenInfo.tokenInfo = tokenInfo;
    }

    modifier setPranker(address pranker) {
        vm.startPrank(pranker);
        _;
        vm.stopPrank();
    }

    // positive cases
    function test_CreateHederaFungibleTokenViaHtsPrecompile() public setPranker(alice) {
        (, bool isToken) = htsPrecompile.isToken(address(0x123));
        assertTrue(isToken == false);
        IHederaTokenService.HederaToken memory token = _getSimpleHederaToken('Token A', 'TA', alice);
        int64 initialTotalSupply = 1e16;
        int32 decimals = 8;
        (int64 responseCode, address tokenAddress) = htsPrecompile.createFungibleToken(
            token,
            initialTotalSupply,
            decimals
        );

        int32 tokenType;
        (, isToken) = htsPrecompile.isToken(tokenAddress);
        (responseCode, tokenType) = htsPrecompile.getTokenType(tokenAddress);

        HederaFungibleToken hederaFungibleToken = HederaFungibleToken(tokenAddress);

        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'Failed to createFungibleToken');

        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'Did not set is{}Token correctly');
        assertEq(tokenType, 0, 'Did not set isFungible correctly');

        assertEq(uint64(initialTotalSupply), hederaFungibleToken.totalSupply(), 'Did not set initial supply correctly');
        assertEq(token.name, hederaFungibleToken.name(), 'Did not set name correctly');
        assertEq(token.symbol, hederaFungibleToken.symbol(), 'Did not set symbol correctly');
        assertEq(
            hederaFungibleToken.totalSupply(),
            hederaFungibleToken.balanceOf(token.treasury),
            'Did not mint initial supply to treasury'
        );
    }

    function test_CreateHederaFungibleTokenDirectly() public setPranker(alice) {
        int64 initialTotalSupply = 1e16;
        int32 decimals = 8;
        IHederaTokenService.FungibleTokenInfo memory fungibleTokenInfo = _getSimpleHederaFungibleTokenInfo(
            'Token A',
            'TA',
            alice,
            initialTotalSupply,
            decimals
        );

        IHederaTokenService.HederaToken memory token = fungibleTokenInfo.tokenInfo.token;

        /// @dev no need to register newly created HederaFungibleToken in this context as the constructor will call HtsPrecompileMock#registerHederaFungibleToken
        HederaFungibleToken hederaFungibleToken = new HederaFungibleToken(fungibleTokenInfo);
        address tokenAddress = address(hederaFungibleToken);

        (int64 responseCode, int32 tokenType) = htsPrecompile.getTokenType(tokenAddress);

        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'Did not set is{}Token correctly');
        assertEq(tokenType, 0, 'Did not set isFungible correctly');

        assertEq(uint64(initialTotalSupply), hederaFungibleToken.totalSupply(), 'Did not set initial supply correctly');
        assertEq(token.name, hederaFungibleToken.name(), 'Did not set name correctly');
        assertEq(token.symbol, hederaFungibleToken.symbol(), 'Did not set symbol correctly');
        assertEq(
            hederaFungibleToken.totalSupply(),
            hederaFungibleToken.balanceOf(token.treasury),
            'Did not mint initial supply to treasury'
        );
    }

    function test_ApproveViaHtsPrecompile() public setPranker(alice) {
        int64 initialTotalSupply = 1e16;
        int32 decimals = 8;
        IHederaTokenService.FungibleTokenInfo memory fungibleTokenInfo = _getSimpleHederaFungibleTokenInfo(
            'Token A',
            'TA',
            alice,
            initialTotalSupply,
            decimals
        );

        IHederaTokenService.HederaToken memory token = fungibleTokenInfo.tokenInfo.token;

        /// @dev no need to register newly created HederaFungibleToken in this context as the constructor will call HtsPrecompileMock#registerHederaFungibleToken
        HederaFungibleToken hederaFungibleToken = new HederaFungibleToken(fungibleTokenInfo);
        address tokenAddress = address(hederaFungibleToken);

        uint allowanceForBob = 1e8;

        uint allowanceBob = hederaFungibleToken.allowance(alice, bob);

        assertEq(allowanceBob, 0, 'expected bob to have a 0 starting allowance');

        int64 responseCode = htsPrecompile.approve(tokenAddress, bob, allowanceForBob);

        assertEq(
            responseCode,
            HederaResponseCodes.TOKEN_NOT_ASSOCIATED_TO_ACCOUNT,
            'expected to not approve due to bob not being associated'
        );

        vm.stopPrank();
        vm.prank(bob);

        responseCode = htsPrecompile.associateToken(bob, tokenAddress);
        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected bob to associate with token');

        assertEq(htsPrecompile.isAssociated(bob, tokenAddress), true, "expected bob to be associated with token");

        vm.startPrank(alice);

        responseCode = htsPrecompile.approve(tokenAddress, bob, allowanceForBob);

        assertEq(
            responseCode,
            HederaResponseCodes.SUCCESS,
            "expected bob to be given token allowance to alice's account"
        );

        allowanceBob = hederaFungibleToken.allowance(alice, bob);

        assertEq(allowanceBob, allowanceForBob, "bob's expected allowance not set correctly");
    }

    function test_ApproveDirectly() public {
        int64 initialTotalSupply = 1e16;
        int32 decimals = 8;
        IHederaTokenService.FungibleTokenInfo memory fungibleTokenInfo = _getSimpleHederaFungibleTokenInfo(
            'Token A',
            'TA',
            alice,
            initialTotalSupply,
            decimals
        );

        IHederaTokenService.HederaToken memory token = fungibleTokenInfo.tokenInfo.token;

        /// @dev no need to register newly created HederaFungibleToken in this context as the constructor will call HtsPrecompileMock#registerHederaFungibleToken
        HederaFungibleToken hederaFungibleToken = new HederaFungibleToken(fungibleTokenInfo);
        address tokenAddress = address(hederaFungibleToken);

        uint allowanceForBob = 1e8;

        uint allowanceBob = hederaFungibleToken.allowance(alice, bob);

        assertEq(allowanceBob, 0, 'expected bob to have a 0 starting allowance');

        vm.expectRevert(abi.encodeWithSelector(HederaFungibleToken.HtsPrecompileError.selector, HederaResponseCodes.TOKEN_NOT_ASSOCIATED_TO_ACCOUNT));
        hederaFungibleToken.approve(bob, allowanceForBob);

        vm.stopPrank();
        vm.prank(bob);

        int64 responseCode = htsPrecompile.associateToken(bob, tokenAddress);
        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected bob to associate with token');

        assertEq(htsPrecompile.isAssociated(bob, tokenAddress), true, "expected bob to be associated with token");

        vm.startPrank(alice);

        bool success = hederaFungibleToken.approve(bob, allowanceForBob);

        assertEq(
            success,
            true,
            "expected bob to be given token allowance to alice's account"
        );

        allowanceBob = hederaFungibleToken.allowance(alice, bob);

        assertEq(allowanceBob, allowanceForBob, "bob's expected allowance not set correctly");
    }

    function test_TransferViaHtsPrecompile() public {}

    function test_TransferDirectly() public {}

    // negative cases
    function test_CannotApproveIfSpenderNotAssociated() public {
        // cannot approve spender if spender is not associated with HederaFungibleToken BOTH directly and viaHtsPrecompile
    }

    function test_CannotTransferIfRecipientNotAssociated() public {
        // cannot transfer to recipient if recipient is not associated with HederaFungibleToken BOTH directly and viaHtsPrecompile
    }
}

// forge test --match-contract HederaFungibleTokenTest --match-test test_ApproveViaHtsPrecompile -vv
// forge test --match-contract HederaFungibleTokenTest -vv