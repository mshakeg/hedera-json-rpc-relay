// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'hedera-smart-contracts/hts-precompile/IHederaTokenService.sol';
import 'hedera-smart-contracts/hts-precompile/HederaResponseCodes.sol';

import '../mocks/hts-precompile/HederaFungibleToken.sol';

import "./CommonUtils.sol";
import "./HederaTokenUtils.sol";

contract HederaFungibleTokenUtils is CommonUtils, HederaTokenUtils {
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
            sender,
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

    function _createSimpleMockFungibleToken(
        address sender,
        IHederaTokenService.TokenKey[] memory keys
    ) internal returns (address tokenAddress) {
        string memory name = 'Token A';
        string memory symbol = 'TA';
        address treasury = sender;
        int64 initialTotalSupply = 1e16;
        int32 decimals = 8;

        tokenAddress = _doCreateHederaFungibleTokenDirectly(
            sender,
            name,
            symbol,
            treasury,
            initialTotalSupply,
            decimals,
            keys
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
        int64 responseCode = htsPrecompile.approve(token, spender, allowance);
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
            hederaFungibleToken.transfer(transferParams.to, transferParams.amount);
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

    struct MintKeys {
        address supplyKey;
        address treasury;
    }

    struct MintInfo {
        uint256 totalSupply;
        uint256 treasuryBalance;
    }

    function _doMintViaHtsPrecompile(
        address sender,
        address token,
        int64 mintAmount
    ) internal setPranker(sender) returns (bool success, int64 responseCode) {
        uint256 mintAmountU256 = uint64(mintAmount);

        HederaFungibleToken hederaFungibleToken = HederaFungibleToken(token);

        bytes[] memory NULL_BYTES = new bytes[](1);

        int64 newTotalSupply;
        int64[] memory serialNumbers;

        int64 expectedResponseCode = HederaResponseCodes.SUCCESS; // assume SUCCESS initially and later overwrite error code accordingly

        MintKeys memory mintKeys = MintKeys({
            supplyKey: htsPrecompile.getKey(token, KeyHelper.KeyType.SUPPLY),
            treasury: htsPrecompile.getTreasuryAccount(token)
        });

        MintInfo memory preMintInfo = MintInfo({
            totalSupply: hederaFungibleToken.totalSupply(),
            treasuryBalance: hederaFungibleToken.balanceOf(mintKeys.treasury)
        });

        if (mintKeys.supplyKey != sender) {
            expectedResponseCode = HederaResponseCodes.INVALID_SUPPLY_KEY;
        }

        if (mintKeys.supplyKey == address(0)) {
            expectedResponseCode = HederaResponseCodes.TOKEN_HAS_NO_SUPPLY_KEY;
        }

        (responseCode, newTotalSupply, serialNumbers) = htsPrecompile.mintToken(token, mintAmount, NULL_BYTES);

        assertEq(expectedResponseCode, responseCode, 'expected response code does not equal actual response code');

        success = responseCode == HederaResponseCodes.SUCCESS;

        MintInfo memory postMintInfo = MintInfo({
            totalSupply: hederaFungibleToken.totalSupply(),
            treasuryBalance: hederaFungibleToken.balanceOf(mintKeys.treasury)
        });

        if (success) {
            assertEq(
                preMintInfo.totalSupply + mintAmountU256,
                postMintInfo.totalSupply,
                'expected total supply to increase by mint amount'
            );
            assertEq(
                preMintInfo.treasuryBalance + mintAmountU256,
                postMintInfo.treasuryBalance,
                'expected treasury balance to increase by mint amount'
            );
        }

        if (!success) {
            assertEq(
                preMintInfo.totalSupply,
                postMintInfo.totalSupply,
                'expected total supply to not change if failed'
            );
            assertEq(
                preMintInfo.treasuryBalance,
                postMintInfo.treasuryBalance,
                'expected treasury balance to not change if failed'
            );
        }
    }

    struct BurnInfo {
        uint256 totalSupply;
        uint256 treasuryBalance;
    }

    function _doBurnViaHtsPrecompile(
        address sender,
        address token,
        int64 burnAmount
    ) internal setPranker(sender) returns (bool success, int64 responseCode) {
        uint256 burnAmountU256 = uint64(burnAmount);

        HederaFungibleToken hederaFungibleToken = HederaFungibleToken(token);

        bytes[] memory NULL_BYTES = new bytes[](1);

        int64 newTotalSupply;
        int64[] memory serialNumbers;

        int64 expectedResponseCode = HederaResponseCodes.SUCCESS; // assume SUCCESS initially and later overwrite error code accordingly

        address treasury = htsPrecompile.getTreasuryAccount(token);

        BurnInfo memory preBurnInfo = BurnInfo({
            totalSupply: hederaFungibleToken.totalSupply(),
            treasuryBalance: hederaFungibleToken.balanceOf(treasury)
        });

        if (treasury != sender) {
            expectedResponseCode = HederaResponseCodes.AUTHORIZATION_FAILED;
        }

        (responseCode, newTotalSupply) = htsPrecompile.burnToken(token, burnAmount, serialNumbers);

        assertEq(expectedResponseCode, responseCode, 'expected response code does not equal actual response code');

        success = responseCode == HederaResponseCodes.SUCCESS;

        BurnInfo memory postBurnInfo = BurnInfo({
            totalSupply: hederaFungibleToken.totalSupply(),
            treasuryBalance: hederaFungibleToken.balanceOf(treasury)
        });

        if (success) {
            assertEq(
                preBurnInfo.totalSupply - burnAmountU256,
                postBurnInfo.totalSupply,
                'expected total supply to decrease by burn amount'
            );
            assertEq(
                preBurnInfo.treasuryBalance - burnAmountU256,
                postBurnInfo.treasuryBalance,
                'expected treasury balance to decrease by burn amount'
            );
        }

        if (!success) {
            assertEq(
                preBurnInfo.totalSupply,
                postBurnInfo.totalSupply,
                'expected total supply to not change if failed'
            );
            assertEq(
                preBurnInfo.treasuryBalance,
                postBurnInfo.treasuryBalance,
                'expected treasury balance to not change if failed'
            );
        }
    }
}
