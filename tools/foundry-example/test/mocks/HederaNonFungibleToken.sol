// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';

import 'hedera-smart-contracts/hts-precompile/HederaResponseCodes.sol';
import 'hedera-smart-contracts/hts-precompile/IHederaTokenService.sol';

contract HederaNonFungibleToken is ERC721 {

    bool public constant IS_FUNGIBLE = false; /// @dev if HederaFungibleToken then true

    constructor(IHederaTokenService.NonFungibleTokenInfo memory _nonFungibleTokenInfo) ERC721(_nonFungibleTokenInfo.tokenInfo.token.name, _nonFungibleTokenInfo.tokenInfo.token.symbol) {
        // TODO: use HederaFungibleToken as a reference
    }
}
