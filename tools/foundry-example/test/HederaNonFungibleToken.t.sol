// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'hedera-smart-contracts/hts-precompile/IHederaTokenService.sol';
import 'hedera-smart-contracts/hts-precompile/HederaResponseCodes.sol';
import 'hedera-smart-contracts/hts-precompile/KeyHelper.sol';
import './mocks/hts-precompile/HederaNonFungibleToken.sol';
import './mocks/hts-precompile/HtsPrecompileMock.sol';

import './utils/HederaNonFungibleTokenUtils.sol';

contract HederaNonFungibleTokenTest is HederaNonFungibleTokenUtils, KeyHelper {
    address alice = vm.addr(1);
    address bob = vm.addr(2);
    address carol = vm.addr(3);
    address dave = vm.addr(4);

    address constant ADDRESS_ZERO = address(0);

    struct Numbers {
        uint numU256;
        int64 numI64;
    }

    // setUp is executed before each and every test function
    function setUp() public {

        _setUpHtsPrecompileMock();

        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(carol, 100 ether);
        vm.deal(dave, 100 ether);
    }

    // positive cases
    function test_CreateHederaNonFungibleTokenViaHtsPrecompile() public {

        address sender = alice;
        string memory name = 'NFT A';
        string memory symbol = 'NFT-A';
        address treasury = bob;

        bool success;

        (success, ) = _doCreateHederaNonFungibleTokenViaHtsPrecompile(sender, name, symbol, treasury);
        assertEq(success, false, "expected failure since treasury is not sender");

        treasury = alice;

        (success, ) = _doCreateHederaNonFungibleTokenViaHtsPrecompile(sender, name, symbol, treasury);
        assertEq(success, true, "expected success since treasury is sender");

    }

    function test_CreateHederaNonFungibleTokenDirectly() public {

        address sender = alice;
        string memory name = 'NFT A';
        string memory symbol = 'NFT-A';
        address treasury = bob;

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](0);

        bool success;

        (success, ) = _doCreateHederaNonFungibleTokenDirectly(sender, name, symbol, treasury, keys);
        assertEq(success, false, "expected failure since treasury is not sender");

        treasury = alice;

        (success, ) = _doCreateHederaNonFungibleTokenDirectly(sender, name, symbol, treasury, keys);
        assertEq(success, true, "expected success since treasury is sender");

    }

    function test_ApproveViaHtsPrecompile() public setPranker(alice) {

        bytes[] memory NULL_BYTES = new bytes[](1);

        IHederaTokenService.TokenInfo memory nftTokenInfo = _getSimpleHederaNftTokenInfo(
            'NFT A',
            'NFT-A',
            alice
        );

        IHederaTokenService.HederaToken memory token = nftTokenInfo.token;

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](1);
        keys[0] = KeyHelper.getSingleKey(KeyHelper.KeyType.SUPPLY, KeyHelper.KeyValueType.CONTRACT_ID, alice);

        nftTokenInfo.token.tokenKeys = keys;

        /// @dev no need to register newly created HederaNonFungibleToken in this context as the constructor will call HtsPrecompileMock#registerHederaNonFungibleToken
        HederaNonFungibleToken hederaNonFungibleToken = new HederaNonFungibleToken(nftTokenInfo);
        address tokenAddress = address(hederaNonFungibleToken);

        uint approveNftSerialId = 1;

        (int64 responseCode, int64 newTotalSupply, int64[] memory serialNumbers) = htsPrecompile.mintToken(tokenAddress, 1, NULL_BYTES);

        uint mintedSerialNumber = uint64(serialNumbers[0]);

        assertEq(
            responseCode,
            HederaResponseCodes.SUCCESS,
            'expected NFT to be minted'
        );

        assertEq(newTotalSupply, 1, 'expected NFT supply to be 1 after first mint');

        assertEq(mintedSerialNumber, approveNftSerialId, 'expected first NFT mint to have serialNumber of 1');

        address approvedAccount = hederaNonFungibleToken.getApproved(approveNftSerialId);

        assertEq(approvedAccount, ADDRESS_ZERO, 'expected approved account to be address(0)');

        responseCode = htsPrecompile.approveNFT(tokenAddress, bob, approveNftSerialId);

        assertEq(
            responseCode,
            HederaResponseCodes.TOKEN_NOT_ASSOCIATED_TO_ACCOUNT,
            'expected to not approve due to bob not being associated'
        );

        vm.stopPrank();
        vm.prank(bob);

        responseCode = htsPrecompile.associateToken(bob, tokenAddress);
        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected bob to associate with token');

        assertEq(htsPrecompile.isAssociated(bob, tokenAddress), true, 'expected bob to be associated with token');

        vm.startPrank(alice);

        responseCode = htsPrecompile.approveNFT(tokenAddress, bob, approveNftSerialId);

        assertEq(
            responseCode,
            HederaResponseCodes.SUCCESS,
            "expected bob to be given NFT approval for alice's NFT"
        );

        approvedAccount = hederaNonFungibleToken.getApproved(approveNftSerialId);

        assertEq(approvedAccount, bob, "bob's expected NFT approval not set correctly");
    }

    function test_ApproveDirectly() public setPranker(alice) {
        bytes[] memory NULL_BYTES = new bytes[](1);

        IHederaTokenService.TokenInfo memory nftTokenInfo = _getSimpleHederaNftTokenInfo(
            'NFT A',
            'NFT-A',
            alice
        );

        IHederaTokenService.HederaToken memory token = nftTokenInfo.token;

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](1);
        keys[0] = KeyHelper.getSingleKey(KeyHelper.KeyType.SUPPLY, KeyHelper.KeyValueType.CONTRACT_ID, alice);

        nftTokenInfo.token.tokenKeys = keys;

        /// @dev no need to register newly created HederaNonFungibleToken in this context as the constructor will call HtsPrecompileMock#registerHederaNonFungibleToken
        HederaNonFungibleToken hederaNonFungibleToken = new HederaNonFungibleToken(nftTokenInfo);
        address tokenAddress = address(hederaNonFungibleToken);

        uint approveNftSerialId = 1;

        (int64 responseCode, int64 newTotalSupply, int64[] memory serialNumbers) = htsPrecompile.mintToken(tokenAddress, 1, NULL_BYTES);

        uint mintedSerialNumber = uint64(serialNumbers[0]);

        assertEq(
            responseCode,
            HederaResponseCodes.SUCCESS,
            'expected NFT to be minted'
        );

        assertEq(newTotalSupply, 1, 'expected NFT supply to be 1 after first mint');

        assertEq(mintedSerialNumber, approveNftSerialId, 'expected first NFT mint to have serialNumber of 1');

        address approvedAccount = hederaNonFungibleToken.getApproved(approveNftSerialId);

        assertEq(approvedAccount, ADDRESS_ZERO, 'expected approved account to be address(0)');

        vm.expectRevert(
            abi.encodeWithSelector(
                HederaNonFungibleToken.HtsPrecompileError.selector,
                HederaResponseCodes.TOKEN_NOT_ASSOCIATED_TO_ACCOUNT
            )
        );
        hederaNonFungibleToken.approve(bob, approveNftSerialId);

        vm.stopPrank();
        vm.prank(bob);

        responseCode = htsPrecompile.associateToken(bob, tokenAddress);
        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected bob to associate with token');

        assertEq(htsPrecompile.isAssociated(bob, tokenAddress), true, 'expected bob to be associated with token');

        vm.startPrank(alice);

        hederaNonFungibleToken.approve(bob, approveNftSerialId);

        approvedAccount = hederaNonFungibleToken.getApproved(approveNftSerialId);

        assertEq(approvedAccount, bob, "bob's expected NFT approval not set correctly");
    }

    function test_TransferViaHtsPrecompile() public setPranker(alice) {

        bytes[] memory NULL_BYTES = new bytes[](1);

        IHederaTokenService.TokenInfo memory nftTokenInfo = _getSimpleHederaNftTokenInfo(
            'NFT A',
            'NFT-A',
            alice
        );

        IHederaTokenService.HederaToken memory token = nftTokenInfo.token;

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](1);
        keys[0] = KeyHelper.getSingleKey(KeyHelper.KeyType.SUPPLY, KeyHelper.KeyValueType.CONTRACT_ID, alice);

        nftTokenInfo.token.tokenKeys = keys;

        /// @dev no need to register newly created HederaNonFungibleToken in this context as the constructor will call HtsPrecompileMock#registerHederaNonFungibleToken
        HederaNonFungibleToken hederaNonFungibleToken = new HederaNonFungibleToken(nftTokenInfo);
        address tokenAddress = address(hederaNonFungibleToken);

        uint transferNftSerialId = 1;

        (int64 responseCode, int64 newTotalSupply, int64[] memory serialNumbers) = htsPrecompile.mintToken(tokenAddress, 1, NULL_BYTES);

        uint mintedSerialNumber = uint64(serialNumbers[0]);

        assertEq(
            responseCode,
            HederaResponseCodes.SUCCESS,
            'expected NFT to be minted'
        );

        assertEq(newTotalSupply, 1, 'expected NFT supply to be 1 after first mint');

        assertEq(mintedSerialNumber, transferNftSerialId, 'expected first NFT mint to have serialNumber of 1');

        vm.stopPrank();
        vm.prank(bob);

        responseCode = htsPrecompile.associateToken(bob, tokenAddress);
        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected bob to associate with token');

        assertEq(htsPrecompile.isAssociated(bob, tokenAddress), true, 'expected bob to be associated with token');

        vm.startPrank(alice);

        int64 transferNftSerialIdI64 = int64(int(transferNftSerialId));

        responseCode = htsPrecompile.transferNFT(tokenAddress, alice, bob, transferNftSerialIdI64);

        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected NFT transfer to be success');

        address newOwner = hederaNonFungibleToken.ownerOf(transferNftSerialId);

        assertEq(newOwner, bob, "expected new owner to be bob");
    }

    function test_TransferDirectly() public setPranker(alice) {

        bytes[] memory NULL_BYTES = new bytes[](1);

        IHederaTokenService.TokenInfo memory nftTokenInfo = _getSimpleHederaNftTokenInfo(
            'NFT A',
            'NFT-A',
            alice
        );

        IHederaTokenService.HederaToken memory token = nftTokenInfo.token;

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](1);
        keys[0] = KeyHelper.getSingleKey(KeyHelper.KeyType.SUPPLY, KeyHelper.KeyValueType.CONTRACT_ID, alice);

        nftTokenInfo.token.tokenKeys = keys;

        /// @dev no need to register newly created HederaNonFungibleToken in this context as the constructor will call HtsPrecompileMock#registerHederaNonFungibleToken
        HederaNonFungibleToken hederaNonFungibleToken = new HederaNonFungibleToken(nftTokenInfo);
        address tokenAddress = address(hederaNonFungibleToken);

        uint transferNftSerialId = 1;

        (int64 responseCode, int64 newTotalSupply, int64[] memory serialNumbers) = htsPrecompile.mintToken(tokenAddress, 1, NULL_BYTES);

        uint mintedSerialNumber = uint64(serialNumbers[0]);

        assertEq(
            responseCode,
            HederaResponseCodes.SUCCESS,
            'expected NFT to be minted'
        );

        assertEq(newTotalSupply, 1, 'expected NFT supply to be 1 after first mint');

        assertEq(mintedSerialNumber, transferNftSerialId, 'expected first NFT mint to have serialNumber of 1');

        vm.stopPrank();
        vm.prank(bob);

        responseCode = htsPrecompile.associateToken(bob, tokenAddress);
        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected bob to associate with token');

        assertEq(htsPrecompile.isAssociated(bob, tokenAddress), true, 'expected bob to be associated with token');

        vm.startPrank(alice);

        int64 transferNftSerialIdI64 = int64(int(transferNftSerialId));

        hederaNonFungibleToken.transferFrom(alice, bob, transferNftSerialId);

        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected NFT transfer to be success');

        address newOwner = hederaNonFungibleToken.ownerOf(transferNftSerialId);

        assertEq(newOwner, bob, "expected new owner to be bob");
    }

    function test_TransferUsingAllowanceViaHtsPrecompile() public setPranker(alice) {

        bytes[] memory NULL_BYTES = new bytes[](1);

        IHederaTokenService.TokenInfo memory nftTokenInfo = _getSimpleHederaNftTokenInfo(
            'NFT A',
            'NFT-A',
            alice
        );

        IHederaTokenService.HederaToken memory token = nftTokenInfo.token;

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](1);
        keys[0] = KeyHelper.getSingleKey(KeyHelper.KeyType.SUPPLY, KeyHelper.KeyValueType.CONTRACT_ID, alice);

        nftTokenInfo.token.tokenKeys = keys;

        /// @dev no need to register newly created HederaNonFungibleToken in this context as the constructor will call HtsPrecompileMock#registerHederaNonFungibleToken
        HederaNonFungibleToken hederaNonFungibleToken = new HederaNonFungibleToken(nftTokenInfo);
        address tokenAddress = address(hederaNonFungibleToken);

        uint nftSerialId = 1;

        (int64 responseCode, int64 newTotalSupply, int64[] memory serialNumbers) = htsPrecompile.mintToken(tokenAddress, 1, NULL_BYTES);

        uint mintedSerialNumber = uint64(serialNumbers[0]);

        assertEq(
            responseCode,
            HederaResponseCodes.SUCCESS,
            'expected NFT to be minted'
        );

        assertEq(newTotalSupply, 1, 'expected NFT supply to be 1 after first mint');

        assertEq(mintedSerialNumber, nftSerialId, 'expected first NFT mint to have serialNumber of 1');

        vm.stopPrank();

        vm.prank(bob);
        responseCode = htsPrecompile.associateToken(bob, tokenAddress);
        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected bob to associate with token');
        assertEq(htsPrecompile.isAssociated(bob, tokenAddress), true, 'expected bob to be associated with token');

        vm.prank(carol);
        responseCode = htsPrecompile.associateToken(carol, tokenAddress);
        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected carol to associate with token');
        assertEq(htsPrecompile.isAssociated(carol, tokenAddress), true, 'expected carol to be associated with token');

        vm.startPrank(alice);

        hederaNonFungibleToken.approve(bob, nftSerialId);

        int64 nftSerialIdI64 = int64(int(nftSerialId));

        vm.stopPrank();
        vm.startPrank(bob);

        responseCode = htsPrecompile.transferNFT(tokenAddress, alice, carol, nftSerialIdI64);

        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected NFT transfer using approval to be success');

        address newOwner = hederaNonFungibleToken.ownerOf(nftSerialId);

        assertEq(newOwner, carol, "expected new owner to be carol");
    }

    function test_TransferUsingAllowanceDirectly() public setPranker(alice) {

        bytes[] memory NULL_BYTES = new bytes[](1);

        IHederaTokenService.TokenInfo memory nftTokenInfo = _getSimpleHederaNftTokenInfo(
            'NFT A',
            'NFT-A',
            alice
        );

        IHederaTokenService.HederaToken memory token = nftTokenInfo.token;

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](1);
        keys[0] = KeyHelper.getSingleKey(KeyHelper.KeyType.SUPPLY, KeyHelper.KeyValueType.CONTRACT_ID, alice);

        nftTokenInfo.token.tokenKeys = keys;

        /// @dev no need to register newly created HederaNonFungibleToken in this context as the constructor will call HtsPrecompileMock#registerHederaNonFungibleToken
        HederaNonFungibleToken hederaNonFungibleToken = new HederaNonFungibleToken(nftTokenInfo);
        address tokenAddress = address(hederaNonFungibleToken);

        uint nftSerialId = 1;

        (int64 responseCode, int64 newTotalSupply, int64[] memory serialNumbers) = htsPrecompile.mintToken(tokenAddress, 1, NULL_BYTES);

        uint mintedSerialNumber = uint64(serialNumbers[0]);

        assertEq(
            responseCode,
            HederaResponseCodes.SUCCESS,
            'expected NFT to be minted'
        );

        assertEq(newTotalSupply, 1, 'expected NFT supply to be 1 after first mint');

        assertEq(mintedSerialNumber, nftSerialId, 'expected first NFT mint to have serialNumber of 1');

        vm.stopPrank();

        vm.prank(bob);
        responseCode = htsPrecompile.associateToken(bob, tokenAddress);
        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected bob to associate with token');
        assertEq(htsPrecompile.isAssociated(bob, tokenAddress), true, 'expected bob to be associated with token');

        vm.prank(carol);
        responseCode = htsPrecompile.associateToken(carol, tokenAddress);
        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected carol to associate with token');
        assertEq(htsPrecompile.isAssociated(carol, tokenAddress), true, 'expected carol to be associated with token');

        vm.startPrank(alice);

        hederaNonFungibleToken.approve(bob, nftSerialId);

        int64 nftSerialIdI64 = int64(int(nftSerialId));

        vm.stopPrank();
        vm.startPrank(bob);

        hederaNonFungibleToken.transferFrom(alice, carol, nftSerialId);

        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected NFT transfer using approval to be success');

        address newOwner = hederaNonFungibleToken.ownerOf(nftSerialId);

        assertEq(newOwner, carol, "expected new owner to be carol");
    }

    /// @dev there is no test_CanMintDirectly as the ERC20 standard does not typically allow direct mints
    function test_CanMintViaHtsPrecompile() public setPranker(alice) {
        bytes[] memory NULL_BYTES = new bytes[](1);

        IHederaTokenService.TokenInfo memory nftTokenInfo = _getSimpleHederaNftTokenInfo(
            'NFT A',
            'NFT-A',
            alice
        );

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](1);
        keys[0] = KeyHelper.getSingleKey(KeyHelper.KeyType.SUPPLY, KeyHelper.KeyValueType.CONTRACT_ID, alice);

        nftTokenInfo.token.tokenKeys = keys;

        IHederaTokenService.HederaToken memory token = nftTokenInfo.token;

        /// @dev no need to register newly created HederaNonFungibleToken in this context as the constructor will call HtsPrecompileMock#registerHederaNonFungibleToken
        HederaNonFungibleToken hederaNonFungibleToken = new HederaNonFungibleToken(nftTokenInfo);
        address tokenAddress = address(hederaNonFungibleToken);

        vm.stopPrank();

        vm.prank(bob);
        int64 responseCode = htsPrecompile.associateToken(bob, tokenAddress);
        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected bob to associate with token');
        assertEq(htsPrecompile.isAssociated(bob, tokenAddress), true, 'expected bob to be associated with token');

        {
            Numbers memory mintAmounts = Numbers({numU256: 1e8, numI64: int64(int(1e8))});

            int64 newTotalSupply;
            int64[] memory serialNumbers;

            (responseCode, newTotalSupply, serialNumbers) = htsPrecompile.mintToken(
                tokenAddress,
                mintAmounts.numI64,
                NULL_BYTES
            );
            assertEq(
                responseCode,
                HederaResponseCodes.INVALID_SUPPLY_KEY,
                'expected mint to fail since bob is not supply key'
            );

            vm.startPrank(alice);

            (responseCode, newTotalSupply, serialNumbers) = htsPrecompile.mintToken(
                tokenAddress,
                mintAmounts.numI64,
                NULL_BYTES
            );

            assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected success since alice is supply key');
        }
    }

    /// @dev there is no test_CanBurnDirectly as the ERC20 standard does not typically allow direct burns
    function test_CanBurnViaHtsPrecompile() public setPranker(alice) {
        bytes[] memory NULL_BYTES = new bytes[](1);

        IHederaTokenService.TokenInfo memory nftTokenInfo = _getSimpleHederaNftTokenInfo(
            'NFT A',
            'NFT-A',
            alice
        );

        IHederaTokenService.HederaToken memory token = nftTokenInfo.token;

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](1);
        keys[0] = KeyHelper.getSingleKey(KeyHelper.KeyType.SUPPLY, KeyHelper.KeyValueType.CONTRACT_ID, alice);

        nftTokenInfo.token.tokenKeys = keys;

        /// @dev no need to register newly created HederaNonFungibleToken in this context as the constructor will call HtsPrecompileMock#registerHederaNonFungibleToken
        HederaNonFungibleToken hederaNonFungibleToken = new HederaNonFungibleToken(nftTokenInfo);
        address tokenAddress = address(hederaNonFungibleToken);

        int64 responseCode;
        int64 newTotalSupply;
        int64[] memory serialNumbers;

        (responseCode, newTotalSupply, serialNumbers) = htsPrecompile.mintToken(tokenAddress, 1, NULL_BYTES);

        uint mintedSerialNumber = uint64(serialNumbers[0]);

        vm.stopPrank();

        vm.prank(bob);
        responseCode = htsPrecompile.associateToken(bob, tokenAddress);
        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected bob to associate with token');
        assertEq(htsPrecompile.isAssociated(bob, tokenAddress), true, 'expected bob to be associated with token');

        vm.startPrank(alice);

        hederaNonFungibleToken.transferFrom(alice, bob, mintedSerialNumber);

        {

            (responseCode, newTotalSupply) = htsPrecompile.burnToken(tokenAddress, 0, serialNumbers);
            assertEq(
                responseCode,
                HederaResponseCodes.INSUFFICIENT_TOKEN_BALANCE,
                'expected burn to fail since alice is not wipe key to wipe the NFT owned by bob'
            );

            vm.stopPrank();
            vm.prank(bob);
            hederaNonFungibleToken.transferFrom(bob, alice, mintedSerialNumber); // transfer back to treasury

            address newOwner = hederaNonFungibleToken.ownerOf(mintedSerialNumber);
            assertEq(newOwner, alice, "expected alice to be the new owner");

            vm.startPrank(alice);
            (responseCode, newTotalSupply) = htsPrecompile.burnToken(tokenAddress, 0, serialNumbers);
            assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected success since alice is treasury');
        }
    }

    // negative cases
    function test_CannotApproveIfSpenderNotAssociated() public {
        /// @dev already demonstrated in some of the postive test cases
        // cannot approve spender if spender is not associated with HederaNonFungibleToken BOTH directly and viaHtsPrecompile
    }

    function test_CannotTransferIfRecipientNotAssociated() public {
        /// @dev already demonstrated in some of the postive test cases
        // cannot transfer to recipient if recipient is not associated with HederaNonFungibleToken BOTH directly and viaHtsPrecompile
    }
}

// forge test --match-contract HederaNonFungibleTokenTest --match-test test_CreateHederaNonFungibleTokenViaHtsPrecompile -vv
// forge test --match-contract HederaNonFungibleTokenTest -vv