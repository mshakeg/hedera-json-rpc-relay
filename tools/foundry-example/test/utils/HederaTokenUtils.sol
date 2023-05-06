// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';

import '../mocks/hts-precompile/HtsPrecompileMock.sol';
import './CommonUtils.sol';

/// for testing actions common to both HTS token types i.e FUNGIBLE and NON_FUNGIBLE
/// also has common constants for both HTS token types
abstract contract HederaTokenUtils is Test, CommonUtils {

    address constant htsPrecompileAddress = address(0x167);

    HtsPrecompileMock htsPrecompile = HtsPrecompileMock(htsPrecompileAddress);

    function _setUpHtsPrecompileMock() internal {
        HtsPrecompileMock htsPrecompileMock = new HtsPrecompileMock();
        bytes memory code = address(htsPrecompileMock).code;
        vm.etch(htsPrecompileAddress, code);
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

    struct MintKeys {
        address supplyKey;
        address treasury;
    }

    struct MintInfo {
        uint256 totalSupply;
        uint256 treasuryBalance;
        bool isFungible;
        bool isNonFungible;
        uint256 mintAmountU256;
        int64 mintCount;
    }

    struct MintParams {
        address sender;
        address token;
        int64 mintAmount;
    }

    struct MintResponse {
        bool success;
        int64 responseCode;
        int64 serialId;
    }

    function _doMintViaHtsPrecompile(MintParams memory mintParams) internal setPranker(mintParams.sender) returns (MintResponse memory mintResponse) {

        HederaFungibleToken hederaFungibleToken = HederaFungibleToken(mintParams.token);
        HederaNonFungibleToken hederaNonFungibleToken = HederaNonFungibleToken(mintParams.token);

        bytes[] memory NULL_BYTES = new bytes[](1);

        int64 newTotalSupply;
        int64[] memory serialNumbers;
        int32 tokenType;

        int64 expectedResponseCode = HederaResponseCodes.SUCCESS; // assume SUCCESS initially and later overwrite error code accordingly

        MintKeys memory mintKeys = MintKeys({
            supplyKey: htsPrecompile.getKey(mintParams.token, KeyHelper.KeyType.SUPPLY),
            treasury: htsPrecompile.getTreasuryAccount(mintParams.token)
        });

        (mintResponse.responseCode, tokenType) = htsPrecompile.getTokenType(mintParams.token);

        mintResponse.success = mintResponse.responseCode == HederaResponseCodes.SUCCESS;

        if (tokenType == 1) {
            /// @dev since you can only mint one NFT at a time; also mintAmount is ONLY applicable to type FUNGIBLE
            mintParams.mintAmount = 1;
        }

        MintInfo memory preMintInfo = MintInfo({
            totalSupply: mintResponse.success ? (tokenType == 0 ? hederaFungibleToken.totalSupply() : hederaNonFungibleToken.totalSupply()) : 0,
            treasuryBalance: mintResponse.success ? (tokenType == 0 ? hederaFungibleToken.balanceOf(mintKeys.treasury) : hederaNonFungibleToken.totalSupply()) : 0,
            isFungible: tokenType == 0 ? true : false,
            isNonFungible: tokenType == 1 ? true : false,
            mintAmountU256: uint64(mintParams.mintAmount),
            mintCount: tokenType == 1 ? hederaNonFungibleToken.mintCount() : int64(0)
        });

        if (mintKeys.supplyKey != mintParams.sender) {
            expectedResponseCode = HederaResponseCodes.INVALID_SUPPLY_KEY;
        }

        if (mintKeys.supplyKey == address(0)) {
            expectedResponseCode = HederaResponseCodes.TOKEN_HAS_NO_SUPPLY_KEY;
        }

        (mintResponse.responseCode, newTotalSupply, serialNumbers) = htsPrecompile.mintToken(mintParams.token, mintParams.mintAmount, NULL_BYTES);

        assertEq(expectedResponseCode, mintResponse.responseCode, 'expected response code does not equal actual response code');

        mintResponse.success = mintResponse.responseCode == HederaResponseCodes.SUCCESS;

        MintInfo memory postMintInfo = MintInfo({
            totalSupply: tokenType == 0 ? hederaFungibleToken.totalSupply() : hederaNonFungibleToken.totalSupply(),
            treasuryBalance: tokenType == 0 ? hederaFungibleToken.balanceOf(mintKeys.treasury) : hederaNonFungibleToken.totalSupply(),
            isFungible: tokenType == 0 ? true : false,
            isNonFungible: tokenType == 1 ? true : false,
            mintAmountU256: uint64(mintParams.mintAmount),
            mintCount: tokenType == 1 ? hederaNonFungibleToken.mintCount() : int64(0)
        });

        if (mintResponse.success) {

            assertEq(
                postMintInfo.totalSupply,
                uint64(newTotalSupply),
                'expected newTotalSupply to equal post mint totalSupply'
            );

            if (preMintInfo.isFungible) {

                assertEq(
                    preMintInfo.totalSupply + preMintInfo.mintAmountU256,
                    postMintInfo.totalSupply,
                    'expected total supply to increase by mint amount'
                );
                assertEq(
                    preMintInfo.treasuryBalance + preMintInfo.mintAmountU256,
                    postMintInfo.treasuryBalance,
                    'expected treasury balance to increase by mint amount'
                );
            }

            if (preMintInfo.isNonFungible) {
                assertEq(
                    preMintInfo.totalSupply + 1,
                    postMintInfo.totalSupply,
                    'expected total supply to increase by mint amount'
                );
                assertEq(
                    preMintInfo.treasuryBalance + 1,
                    postMintInfo.treasuryBalance,
                    'expected treasury balance to increase by mint amount'
                );

                assertEq(preMintInfo.mintCount + 1, postMintInfo.mintCount, "expected mintCount to increase by 1");
                assertEq(serialNumbers[0], postMintInfo.mintCount, "expected minted serialNumber to equal mintCount");

                mintResponse.serialId = serialNumbers[0];
            }
        }

        if (!mintResponse.success) {
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

}
