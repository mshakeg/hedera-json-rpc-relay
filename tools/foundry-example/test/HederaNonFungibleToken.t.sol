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

    function test_ApproveViaHtsPrecompile() public {

        bytes[] memory NULL_BYTES = new bytes[](1);

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](1);
        keys[0] = KeyHelper.getSingleKey(KeyHelper.KeyType.SUPPLY, KeyHelper.KeyValueType.CONTRACT_ID, alice);
        address tokenAddress = _createSimpleMockNonFungibleToken(alice, keys);

        bool success;

        MintResponse memory mintResponse;
        MintParams memory mintParams;

        mintParams = MintParams({
            sender: bob,
            token: tokenAddress,
            mintAmount: 0
        });

        mintResponse = _doMintViaHtsPrecompile(mintParams);
        assertEq(mintResponse.success, false, "expected failure since bob is not supply key");

        mintParams = MintParams({
            sender: alice,
            token: tokenAddress,
            mintAmount: 0
        });

        mintResponse = _doMintViaHtsPrecompile(mintParams);
        assertEq(mintResponse.success, true, "expected success since alice is supply key");

        success = _doAssociateViaHtsPrecompile(bob, tokenAddress);
        assertEq(success, true, "bob should have associated with token");

        ApproveNftParams memory approveNftParams;

        approveNftParams = ApproveNftParams({
            sender: bob,
            token: tokenAddress,
            spender: carol,
            serialId: mintResponse.serialId
        });

        success = _doApproveNftViaHtsPrecompile(approveNftParams);
        assertEq(success, false, "should have failed as bob does not own NFT with serialId");

        approveNftParams = ApproveNftParams({
            sender: alice,
            token: tokenAddress,
            spender: carol,
            serialId: mintResponse.serialId
        });

        success = _doApproveNftViaHtsPrecompile(approveNftParams);
        assertEq(success, true, "should have succeeded as alice does own NFT with serialId");
    }

    function test_ApproveDirectly() public {

        bytes[] memory NULL_BYTES = new bytes[](1);

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](1);
        keys[0] = KeyHelper.getSingleKey(KeyHelper.KeyType.SUPPLY, KeyHelper.KeyValueType.CONTRACT_ID, alice);
        address tokenAddress = _createSimpleMockNonFungibleToken(alice, keys);

        bool success;

        MintResponse memory mintResponse;
        MintParams memory mintParams;

        mintParams = MintParams({
            sender: alice,
            token: tokenAddress,
            mintAmount: 0
        });

        mintResponse = _doMintViaHtsPrecompile(mintParams);
        assertEq(mintResponse.success, true, "expected success since alice is supply key");

        success = _doAssociateViaHtsPrecompile(bob, tokenAddress);
        assertEq(success, true, "bob should have associated with token");

        ApproveNftParams memory approveNftParams;

        approveNftParams = ApproveNftParams({
            sender: bob,
            token: tokenAddress,
            spender: carol,
            serialId: mintResponse.serialId
        });

        success = _doApproveNftDirectly(approveNftParams);
        assertEq(success, false, "should have failed as bob does not own NFT with serialId");

        approveNftParams = ApproveNftParams({
            sender: alice,
            token: tokenAddress,
            spender: carol,
            serialId: mintResponse.serialId
        });

        success = _doApproveNftDirectly(approveNftParams);
        assertEq(success, true, "should have succeeded as alice does own NFT with serialId");
    }

    function test_TransferViaHtsPrecompile() public {

        bytes[] memory NULL_BYTES = new bytes[](1);

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](1);
        keys[0] = KeyHelper.getSingleKey(KeyHelper.KeyType.SUPPLY, KeyHelper.KeyValueType.CONTRACT_ID, alice);
        address tokenAddress = _createSimpleMockNonFungibleToken(alice, keys);

        bool success;
        uint256 serialIdU256;

        MintResponse memory mintResponse;
        MintParams memory mintParams;

        mintParams = MintParams({
            sender: alice,
            token: tokenAddress,
            mintAmount: 0
        });

        mintResponse = _doMintViaHtsPrecompile(mintParams);
        serialIdU256 = uint64(mintResponse.serialId);

        assertEq(mintResponse.success, true, "expected success since alice is supply key");

        success = _doAssociateViaHtsPrecompile(bob, tokenAddress);
        assertEq(success, true, "bob should have associated with token");

        TransferParams memory transferParams;

        transferParams = TransferParams({
            sender: bob,
            token: tokenAddress,
            from: alice,
            to: carol,
            amountOrSerialNumber: serialIdU256
        });

        (success, ) = _doTransferViaHtsPrecompile(transferParams);
        assertEq(success, false, 'expected fail since bob does not own nft or have approval');

        transferParams = TransferParams({
            sender: alice,
            token: tokenAddress,
            from: alice,
            to: carol,
            amountOrSerialNumber: serialIdU256
        });

        (success, ) = _doTransferViaHtsPrecompile(transferParams);
        assertEq(success, false, 'expected fail since carol is not associated with nft');

        transferParams = TransferParams({
            sender: alice,
            token: tokenAddress,
            from: alice,
            to: bob,
            amountOrSerialNumber: serialIdU256
        });

        (success, ) = _doTransferViaHtsPrecompile(transferParams);
        assertEq(success, true, 'expected success');
    }

    function test_TransferDirectly() public {

        bytes[] memory NULL_BYTES = new bytes[](1);

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](1);
        keys[0] = KeyHelper.getSingleKey(KeyHelper.KeyType.SUPPLY, KeyHelper.KeyValueType.CONTRACT_ID, alice);
        address tokenAddress = _createSimpleMockNonFungibleToken(alice, keys);

        bool success;
        uint256 serialIdU256;

        MintResponse memory mintResponse;
        MintParams memory mintParams;

        mintParams = MintParams({
            sender: alice,
            token: tokenAddress,
            mintAmount: 0
        });

        mintResponse = _doMintViaHtsPrecompile(mintParams);
        serialIdU256 = uint64(mintResponse.serialId);

        assertEq(mintResponse.success, true, "expected success since alice is supply key");

        success = _doAssociateViaHtsPrecompile(bob, tokenAddress);
        assertEq(success, true, "bob should have associated with token");

        TransferParams memory transferParams;

        transferParams = TransferParams({
            sender: bob,
            token: tokenAddress,
            from: alice,
            to: carol,
            amountOrSerialNumber: serialIdU256
        });

        (success, ) = _doTransferDirectly(transferParams);
        assertEq(success, false, 'expected fail since bob does not own nft or have approval');

        transferParams = TransferParams({
            sender: alice,
            token: tokenAddress,
            from: alice,
            to: carol,
            amountOrSerialNumber: serialIdU256
        });

        (success, ) = _doTransferDirectly(transferParams);
        assertEq(success, false, 'expected fail since carol is not associated with nft');

        transferParams = TransferParams({
            sender: alice,
            token: tokenAddress,
            from: alice,
            to: bob,
            amountOrSerialNumber: serialIdU256
        });

        (success, ) = _doTransferDirectly(transferParams);
        assertEq(success, true, 'expected success');
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