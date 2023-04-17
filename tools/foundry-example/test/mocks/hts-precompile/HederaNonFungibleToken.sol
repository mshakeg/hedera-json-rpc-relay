// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';

import 'hedera-smart-contracts/hts-precompile/HederaResponseCodes.sol';
import 'hedera-smart-contracts/hts-precompile/IHederaTokenService.sol';
import './HtsPrecompileMock.sol';

contract HederaNonFungibleToken is ERC721 {

    error HtsPrecompileError(int64 responseCode);
    address constant ADDRESS_ZERO = address(0);

    address internal constant HTS_PRECOMPILE = address(0x167);
    HtsPrecompileMock internal constant HtsPrecompile = HtsPrecompileMock(HTS_PRECOMPILE);

    bool public constant IS_FUNGIBLE = false; /// @dev if HederaFungibleToken then true

    /// @dev NonFungibleTokenInfo is for each NFT(with a unique serial number) that is minted; however TokenInfo covers the common token info across all instances
    constructor(
        IHederaTokenService.TokenInfo memory _nftTokenInfo
    ) ERC721(_nftTokenInfo.token.name, _nftTokenInfo.token.symbol) {
        HtsPrecompile.registerHederaNonFungibleToken(_nftTokenInfo);
    }
}
