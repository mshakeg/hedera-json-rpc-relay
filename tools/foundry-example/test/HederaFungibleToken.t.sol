// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import 'forge-std/console.sol';

import 'hedera-smart-contracts/hts-precompile/IHederaTokenService.sol';
import 'hedera-smart-contracts/hts-precompile/HederaResponseCodes.sol';
import 'hedera-smart-contracts/hts-precompile/KeyHelper.sol';
import './mocks/hts-precompile/HederaFungibleToken.sol';
import './mocks/hts-precompile/HtsPrecompileMock.sol';

// TODO: refactor for actions to be standalone internal functions with assertions inside
// TODO: do validation on token at creation
// TODO: complete other precompile contracts implementation and test suite
// TODO: do validations in _precheck functions such that never reverts with error strings in ERC{20/721}
// TODO: investigate ordering of response codes on Hedera and adjust ordering in mocks accordingly

contract HederaFungibleTokenTest is Test, KeyHelper {
    address alice = vm.addr(1);
    address bob = vm.addr(2);
    address carol = vm.addr(3);
    address dave = vm.addr(4);

    address constant htsPrecompileAddress = address(0x167);

    HtsPrecompileMock htsPrecompile = HtsPrecompileMock(htsPrecompileAddress);

    struct Balances {
        uint alice;
        uint bob;
        uint carol;
        uint dave;
    }

    struct Numbers {
        uint numU256;
        int64 numI64;
    }

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

    function _doCreateHederaFungibleTokenViaHtsPrecompile(
        address sender,
        string memory name,
        string memory symbol,
        address treasury,
        int64 initialTotalSupply,
        int32 decimals
    ) internal setPranker(sender) returns (address tokenAddress) {
        bool isToken;
        assertTrue(isToken == false);
        IHederaTokenService.HederaToken memory token = _getSimpleHederaToken(name, symbol, treasury);

        int64 responseCode;
        (responseCode, tokenAddress) = htsPrecompile.createFungibleToken(token, initialTotalSupply, decimals);

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

    function _doCreateHederaFungibleTokenDirectly(
        address sender,
        string memory name,
        string memory symbol,
        address treasury,
        int64 initialTotalSupply,
        int32 decimals,
        IHederaTokenService.TokenKey[] memory keys
    ) internal setPranker(sender) returns (address tokenAddress) {
        IHederaTokenService.FungibleTokenInfo memory fungibleTokenInfo = _getSimpleHederaFungibleTokenInfo(
            name,
            symbol,
            alice,
            initialTotalSupply,
            decimals
        );

        fungibleTokenInfo.tokenInfo.token.tokenKeys = keys;

        IHederaTokenService.HederaToken memory token = fungibleTokenInfo.tokenInfo.token;

        /// @dev no need to register newly created HederaFungibleToken in this context as the constructor will call HtsPrecompileMock#registerHederaFungibleToken
        HederaFungibleToken hederaFungibleToken = new HederaFungibleToken(fungibleTokenInfo);
        tokenAddress = address(hederaFungibleToken);

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

    function _doAssociateViaHtsPrecompile(
        address sender,
        address token
    ) internal setPranker(sender) returns (bool success) {
        bool isInitiallyAssociated = htsPrecompile.isAssociated(sender, token);
        int64 responseCode = htsPrecompile.associateToken(sender, token);
        success = responseCode == HederaResponseCodes.SUCCESS;

        int64 expectedResponseCode;

        if (isInitiallyAssociated) {
            expectedResponseCode = HederaResponseCodes.TOKEN_ALREADY_ASSOCIATED_TO_ACCOUNT;
        }

        if (!isInitiallyAssociated) {
            expectedResponseCode = HederaResponseCodes.SUCCESS;
        }

        bool isFinallyAssociated = htsPrecompile.isAssociated(sender, token);

        assertEq(responseCode, expectedResponseCode, 'expected response code does not match actual response code');
    }

    function _doApproveViaHtsPrecompile(
        address sender,
        address token,
        address spender,
        uint allowance
    ) internal setPranker(sender) returns (bool success) {
        HederaFungibleToken hederaFungibleToken = HederaFungibleToken(token);
        uint spenderStartingAllowance = hederaFungibleToken.allowance(sender, spender);
        int64 responseCode = htsPrecompile.approve(token, bob, allowance);
        assertEq(
            responseCode,
            HederaResponseCodes.SUCCESS,
            "expected spender to be given token allowance to sender's account"
        );

        uint spenderFinalAllowance = hederaFungibleToken.allowance(sender, spender);

        assertEq(spenderFinalAllowance, allowance, "spender's expected allowance not set correctly");
    }

    function _doApproveDirectly(
        address sender,
        address token,
        address spender,
        uint allowance
    ) internal setPranker(sender) returns (bool success) {
        HederaFungibleToken hederaFungibleToken = HederaFungibleToken(token);
        uint spenderStartingAllowance = hederaFungibleToken.allowance(sender, spender);
        success = hederaFungibleToken.approve(spender, allowance);
        assertEq(success, true, 'expected successful approval');
        uint spenderFinalAllowance = hederaFungibleToken.allowance(sender, spender);
        assertEq(spenderFinalAllowance, allowance, "spender's expected allowance not set correctly");
    }

    struct TransferParams {
        address sender;
        address token;
        address from;
        address to;
        uint256 amount;
    }

    struct TransferInfo {
        uint256 spenderAllowance;
        uint256 fromBalance;
        uint256 toBalance;
    }

    struct TransferChecks {
        bool isRecipientAssociated;
        bool isRequestFromOwner;
        int64 expectedResponseCode;
    }

    function _doTransferViaHtsPrecompile(
        TransferParams memory transferParams
    ) internal setPranker(transferParams.sender) returns (bool success, int64 responseCode) {
        HederaFungibleToken hederaFungibleToken = HederaFungibleToken(transferParams.token);

        TransferChecks memory transferChecks = TransferChecks({
            isRecipientAssociated: htsPrecompile.isAssociated(transferParams.to, transferParams.token),
            isRequestFromOwner: transferParams.sender == transferParams.from,
            expectedResponseCode: HederaResponseCodes.SUCCESS // assume SUCCESS and overwrite with !SUCCESS where applicable
        });

        TransferInfo memory preTransferInfo = TransferInfo({
            spenderAllowance: hederaFungibleToken.allowance(transferParams.from, transferParams.sender),
            fromBalance: hederaFungibleToken.balanceOf(transferParams.from),
            toBalance: hederaFungibleToken.balanceOf(transferParams.to)
        });

        if (transferChecks.isRequestFromOwner) {
            if (preTransferInfo.fromBalance < transferParams.amount) {
                transferChecks.expectedResponseCode = HederaResponseCodes.INSUFFICIENT_TOKEN_BALANCE;
            }
        }

        if (!transferChecks.isRequestFromOwner) {
            if (preTransferInfo.spenderAllowance < transferParams.amount) {
                transferChecks.expectedResponseCode = HederaResponseCodes.AMOUNT_EXCEEDS_ALLOWANCE;
            }
        }

        if (!transferChecks.isRecipientAssociated) {
            transferChecks.expectedResponseCode = HederaResponseCodes.TOKEN_NOT_ASSOCIATED_TO_ACCOUNT;
        }

        responseCode = htsPrecompile.transferFrom(
            transferParams.token,
            transferParams.from,
            transferParams.to,
            transferParams.amount
        );

        assertEq(
            transferChecks.expectedResponseCode,
            responseCode,
            'expected response code does not equal actual response code'
        );

        success = responseCode == HederaResponseCodes.SUCCESS;

        TransferInfo memory postTransferInfo = TransferInfo({
            spenderAllowance: hederaFungibleToken.allowance(transferParams.from, transferParams.sender),
            fromBalance: hederaFungibleToken.balanceOf(transferParams.from),
            toBalance: hederaFungibleToken.balanceOf(transferParams.to)
        });

        if (success) {
            assertEq(
                preTransferInfo.toBalance + transferParams.amount,
                postTransferInfo.toBalance,
                'to balance did not update correctly'
            );
            assertEq(
                preTransferInfo.fromBalance - transferParams.amount,
                postTransferInfo.fromBalance,
                'from balance did not update correctly'
            );

            if (!transferChecks.isRequestFromOwner) {
                assertEq(
                    preTransferInfo.spenderAllowance - transferParams.amount,
                    postTransferInfo.spenderAllowance,
                    'spender allowance did not update correctly'
                );
            }
        }

        if (!success) {
            assertEq(preTransferInfo.toBalance, postTransferInfo.toBalance, 'to balance changed unexpectedly');
            assertEq(preTransferInfo.fromBalance, postTransferInfo.fromBalance, 'from balance changed unexpectedly');

            if (!transferChecks.isRequestFromOwner) {
                assertEq(
                    preTransferInfo.spenderAllowance,
                    postTransferInfo.spenderAllowance,
                    'spender allowance changed unexpectedly'
                );
            }
        }
    }

    function _doTransferDirectly(
        TransferParams memory transferParams
    ) internal setPranker(transferParams.sender) returns (bool success, int64 responseCode) {
        HederaFungibleToken hederaFungibleToken = HederaFungibleToken(transferParams.token);

        TransferChecks memory transferChecks = TransferChecks({
            isRecipientAssociated: htsPrecompile.isAssociated(transferParams.to, transferParams.token),
            isRequestFromOwner: transferParams.sender == transferParams.from,
            expectedResponseCode: HederaResponseCodes.SUCCESS // assume SUCCESS and overwrite with !SUCCESS where applicable
        });

        TransferInfo memory preTransferInfo = TransferInfo({
            spenderAllowance: hederaFungibleToken.allowance(transferParams.from, transferParams.sender),
            fromBalance: hederaFungibleToken.balanceOf(transferParams.from),
            toBalance: hederaFungibleToken.balanceOf(transferParams.to)
        });

        if (transferChecks.isRequestFromOwner) {
            if (preTransferInfo.fromBalance < transferParams.amount) {
                transferChecks.expectedResponseCode = HederaResponseCodes.INSUFFICIENT_TOKEN_BALANCE;
            }
        }

        if (!transferChecks.isRequestFromOwner) {
            if (preTransferInfo.spenderAllowance < transferParams.amount) {
                transferChecks.expectedResponseCode = HederaResponseCodes.AMOUNT_EXCEEDS_ALLOWANCE;
            }
        }

        if (!transferChecks.isRecipientAssociated) {
            transferChecks.expectedResponseCode = HederaResponseCodes.TOKEN_NOT_ASSOCIATED_TO_ACCOUNT;
        }

        if (transferChecks.expectedResponseCode != HederaResponseCodes.SUCCESS) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    HederaFungibleToken.HtsPrecompileError.selector,
                    transferChecks.expectedResponseCode
                )
            );
        }

        if (transferChecks.isRequestFromOwner) {
            hederaFungibleToken.transfer(
                transferParams.to,
                transferParams.amount
            );
        }

        if (!transferChecks.isRequestFromOwner) {
            hederaFungibleToken.transferFrom(transferParams.from, transferParams.to, transferParams.amount);
        }

        if (transferChecks.expectedResponseCode == HederaResponseCodes.SUCCESS) {
            success = true;
        }

        TransferInfo memory postTransferInfo = TransferInfo({
            spenderAllowance: hederaFungibleToken.allowance(transferParams.from, transferParams.sender),
            fromBalance: hederaFungibleToken.balanceOf(transferParams.from),
            toBalance: hederaFungibleToken.balanceOf(transferParams.to)
        });

        if (success) {
            assertEq(
                preTransferInfo.toBalance + transferParams.amount,
                postTransferInfo.toBalance,
                'to balance did not update correctly'
            );
            assertEq(
                preTransferInfo.fromBalance - transferParams.amount,
                postTransferInfo.fromBalance,
                'from balance did not update correctly'
            );

            if (!transferChecks.isRequestFromOwner) {
                assertEq(
                    preTransferInfo.spenderAllowance - transferParams.amount,
                    postTransferInfo.spenderAllowance,
                    'spender allowance did not update correctly'
                );
            }
        }

        if (!success) {
            assertEq(preTransferInfo.toBalance, postTransferInfo.toBalance, 'to balance changed unexpectedly');
            assertEq(preTransferInfo.fromBalance, postTransferInfo.fromBalance, 'from balance changed unexpectedly');

            if (!transferChecks.isRequestFromOwner) {
                assertEq(
                    preTransferInfo.spenderAllowance,
                    postTransferInfo.spenderAllowance,
                    'spender allowance changed unexpectedly'
                );
            }
        }
    }

    function _doMintViaHtsPrecompile(address sender, address token) internal setPranker(sender) returns (bool success) {

        bytes[] memory NULL_BYTES = new bytes[](1);

    }

    modifier setPranker(address pranker) {
        vm.startPrank(pranker);
        _;
        vm.stopPrank();
    }

    // positive cases
    function test_CreateHederaFungibleTokenViaHtsPrecompile() public {
        address sender = alice;
        string memory name = 'Token A';
        string memory symbol = 'TA';
        address treasury = alice;
        int64 initialTotalSupply = 1e16;
        int32 decimals = 8;

        _doCreateHederaFungibleTokenViaHtsPrecompile(sender, name, symbol, treasury, initialTotalSupply, decimals);
    }

    function test_CreateHederaFungibleTokenDirectly() public {
        address sender = alice;
        string memory name = 'Token A';
        string memory symbol = 'TA';
        address treasury = alice;
        int64 initialTotalSupply = 1e16;
        int32 decimals = 8;

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](0);

        _doCreateHederaFungibleTokenDirectly(sender, name, symbol, treasury, initialTotalSupply, decimals, keys);
    }

    function test_ApproveViaHtsPrecompile() public {
        address sender = alice;
        string memory name = 'Token A';
        string memory symbol = 'TA';
        address treasury = alice;
        int64 initialTotalSupply = 1e16;
        int32 decimals = 8;

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](0);

        address tokenAddress = _doCreateHederaFungibleTokenDirectly(
            sender,
            name,
            symbol,
            treasury,
            initialTotalSupply,
            decimals,
            keys
        );

        uint allowance = 1e8;
        _doApproveViaHtsPrecompile(alice, tokenAddress, bob, allowance);
    }

    function test_ApproveDirectly() public {
        address sender = alice;
        string memory name = 'Token A';
        string memory symbol = 'TA';
        address treasury = alice;
        int64 initialTotalSupply = 1e16;
        int32 decimals = 8;

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](0);

        address tokenAddress = _doCreateHederaFungibleTokenDirectly(
            sender,
            name,
            symbol,
            treasury,
            initialTotalSupply,
            decimals,
            keys
        );

        uint allowance = 1e8;
        _doApproveDirectly(alice, tokenAddress, bob, allowance);
    }

    function test_TransferViaHtsPrecompile() public {
        address sender = alice;
        string memory name = 'Token A';
        string memory symbol = 'TA';
        address treasury = alice;
        int64 initialTotalSupply = 1e16;
        int32 decimals = 8;

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](0);

        address tokenAddress = _doCreateHederaFungibleTokenDirectly(
            sender,
            name,
            symbol,
            treasury,
            initialTotalSupply,
            decimals,
            keys
        );

        bool success;
        uint256 amount = 1e8;

        TransferParams memory transferParams = TransferParams({
            sender: alice,
            token: tokenAddress,
            from: alice,
            to: bob,
            amount: amount
        });

        (success, ) = _doTransferViaHtsPrecompile(transferParams);
        assertEq(success, false, 'expected transfer to fail since recipient is not associated with token');

        success = _doAssociateViaHtsPrecompile(bob, tokenAddress);
        assertEq(success, true, 'expected bob to associate with token');

        (success, ) = _doTransferViaHtsPrecompile(transferParams);
        assertEq(success, true, 'expected transfer to succeed');
    }

    function test_TransferDirectly() public {
        address sender = alice;
        string memory name = 'Token A';
        string memory symbol = 'TA';
        address treasury = alice;
        int64 initialTotalSupply = 1e16;
        int32 decimals = 8;

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](0);

        address tokenAddress = _doCreateHederaFungibleTokenDirectly(
            sender,
            name,
            symbol,
            treasury,
            initialTotalSupply,
            decimals,
            keys
        );

        bool success;
        uint256 amount = 1e8;

        TransferParams memory transferParams = TransferParams({
            sender: alice,
            token: tokenAddress,
            from: alice,
            to: bob,
            amount: amount
        });

        (success, ) = _doTransferDirectly(transferParams);
        assertEq(success, false, 'expected transfer to fail since recipient is not associated with token');

        success = _doAssociateViaHtsPrecompile(bob, tokenAddress);
        assertEq(success, true, 'expected bob to associate with token');

        (success, ) = _doTransferDirectly(transferParams);
        assertEq(success, true, 'expected transfer to succeed');
    }

    function test_TransferUsingAllowanceViaHtsPrecompile() public {
        address sender = alice;
        string memory name = 'Token A';
        string memory symbol = 'TA';
        address treasury = alice;
        int64 initialTotalSupply = 1e16;
        int32 decimals = 8;

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](0);

        address tokenAddress = _doCreateHederaFungibleTokenDirectly(
            sender,
            name,
            symbol,
            treasury,
            initialTotalSupply,
            decimals,
            keys
        );

        bool success;
        uint256 amount = 1e8;

        TransferParams memory transferParams = TransferParams({
            sender: bob,
            token: tokenAddress,
            from: alice,
            to: bob,
            amount: amount
        });

        (success, ) = _doTransferViaHtsPrecompile(transferParams);
        assertEq(success, false, 'expected transfer to fail since bob is not associated with token');

        success = _doAssociateViaHtsPrecompile(bob, tokenAddress);
        assertEq(success, true, 'expected bob to associate with token');

        (success, ) = _doTransferViaHtsPrecompile(transferParams);
        assertEq(success, false, 'expected transfer to fail since bob is not granted an allowance');

        uint allowance = 1e8;
        _doApproveViaHtsPrecompile(alice, tokenAddress, bob, allowance);

        (success, ) = _doTransferViaHtsPrecompile(transferParams);
        assertEq(success, true, 'expected transfer to succeed');
    }

    function test_TransferUsingAllowanceDirectly() public {
        address sender = alice;
        string memory name = 'Token A';
        string memory symbol = 'TA';
        address treasury = alice;
        int64 initialTotalSupply = 1e16;
        int32 decimals = 8;

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](0);

        address tokenAddress = _doCreateHederaFungibleTokenDirectly(
            sender,
            name,
            symbol,
            treasury,
            initialTotalSupply,
            decimals,
            keys
        );

        bool success;
        uint256 amount = 1e8;

        TransferParams memory transferParams = TransferParams({
            sender: bob,
            token: tokenAddress,
            from: alice,
            to: bob,
            amount: amount
        });

        (success, ) = _doTransferDirectly(transferParams);
        assertEq(success, false, 'expected transfer to fail since bob is not associated with token');

        success = _doAssociateViaHtsPrecompile(bob, tokenAddress);
        assertEq(success, true, 'expected bob to associate with token');

        (success, ) = _doTransferDirectly(transferParams);
        assertEq(success, false, 'expected transfer to fail since bob is not granted an allowance');

        uint allowance = 1e8;
        _doApproveViaHtsPrecompile(alice, tokenAddress, bob, allowance);

        (success, ) = _doTransferDirectly(transferParams);
        assertEq(success, true, 'expected transfer to succeed');
    }

    /// @dev there is no test_CanMintDirectly as the ERC20 standard does not typically allow direct mints
    function test_CanMintViaHtsPrecompile() public setPranker(alice) {
        bytes[] memory NULL_BYTES = new bytes[](1);

        int64 initialTotalSupply = 1e16;
        uint initialTotalSupplyU256 = uint64(initialTotalSupply);

        IHederaTokenService.FungibleTokenInfo memory fungibleTokenInfo = _getSimpleHederaFungibleTokenInfo(
            'Token A',
            'TA',
            alice,
            initialTotalSupply,
            8
        );

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](1);
        keys[0] = KeyHelper.getSingleKey(KeyHelper.KeyType.SUPPLY, KeyHelper.KeyValueType.CONTRACT_ID, alice);

        fungibleTokenInfo.tokenInfo.token.tokenKeys = keys;

        IHederaTokenService.HederaToken memory token = fungibleTokenInfo.tokenInfo.token;

        /// @dev no need to register newly created HederaFungibleToken in this context as the constructor will call HtsPrecompileMock#registerHederaFungibleToken
        HederaFungibleToken hederaFungibleToken = new HederaFungibleToken(fungibleTokenInfo);
        address tokenAddress = address(hederaFungibleToken);

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

            Balances memory balances = Balances({
                alice: hederaFungibleToken.balanceOf(alice),
                bob: hederaFungibleToken.balanceOf(bob),
                carol: 0,
                dave: 0
            });

            assertEq(
                balances.alice,
                initialTotalSupplyU256 + mintAmounts.numU256,
                'expected alice balance to increase by mintAmount'
            );
            assertEq(balances.bob, 0, 'expected bob to still have 0 balance');
        }
    }

    /// @dev there is no test_CanBurnDirectly as the ERC20 standard does not typically allow direct burns
    function test_CanBurnViaHtsPrecompile() public setPranker(alice) {
        bytes[] memory NULL_BYTES = new bytes[](1);

        int64 initialTotalSupply = 1e16;
        uint initialTotalSupplyU256 = uint64(initialTotalSupply);

        IHederaTokenService.FungibleTokenInfo memory fungibleTokenInfo = _getSimpleHederaFungibleTokenInfo(
            'Token A',
            'TA',
            alice,
            initialTotalSupply,
            8
        );

        IHederaTokenService.HederaToken memory token = fungibleTokenInfo.tokenInfo.token;

        /// @dev no need to register newly created HederaFungibleToken in this context as the constructor will call HtsPrecompileMock#registerHederaFungibleToken
        HederaFungibleToken hederaFungibleToken = new HederaFungibleToken(fungibleTokenInfo);
        address tokenAddress = address(hederaFungibleToken);

        vm.stopPrank();

        vm.prank(bob);
        int64 responseCode = htsPrecompile.associateToken(bob, tokenAddress);
        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected bob to associate with token');
        assertEq(htsPrecompile.isAssociated(bob, tokenAddress), true, 'expected bob to be associated with token');

        {
            Numbers memory burnAmounts = Numbers({numU256: 1e8, numI64: int64(int(1e8))});

            int64 newTotalSupply;
            int64[] memory serialNumbers;

            (responseCode, newTotalSupply) = htsPrecompile.burnToken(tokenAddress, burnAmounts.numI64, serialNumbers);
            assertEq(
                responseCode,
                HederaResponseCodes.AUTHORIZATION_FAILED,
                'expected burn to fail since bob is not treasury'
            );

            vm.startPrank(alice);

            (responseCode, newTotalSupply) = htsPrecompile.burnToken(tokenAddress, burnAmounts.numI64, serialNumbers);

            assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected success since alice is treasury');

            Balances memory balances = Balances({
                alice: hederaFungibleToken.balanceOf(alice),
                bob: hederaFungibleToken.balanceOf(bob),
                carol: 0,
                dave: 0
            });

            assertEq(
                balances.alice,
                initialTotalSupplyU256 - burnAmounts.numU256,
                'expected alice balance to decrease by burnAmount'
            );
            assertEq(balances.bob, 0, 'expected bob to still have 0 balance');
        }
    }

    // negative cases
    function test_CannotApproveIfSpenderNotAssociated() public {
        /// @dev already demonstrated in some of the postive test cases
        // cannot approve spender if spender is not associated with HederaFungibleToken BOTH directly and viaHtsPrecompile
    }

    function test_CannotTransferIfRecipientNotAssociated() public {
        /// @dev already demonstrated in some of the postive test cases
        // cannot transfer to recipient if recipient is not associated with HederaFungibleToken BOTH directly and viaHtsPrecompile
    }
}

// forge test --match-contract HederaFungibleTokenTest --match-test test_ApproveViaHtsPrecompile -vv
// forge test --match-contract HederaFungibleTokenTest -vv