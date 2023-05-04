// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'hedera-smart-contracts/hts-precompile/IHederaTokenService.sol';
import 'hedera-smart-contracts/hts-precompile/HederaResponseCodes.sol';

import '../mocks/hts-precompile/HederaFungibleToken.sol';

import "./CommonUtils.sol";
import "./HederaTokenUtils.sol";

contract HederaNonFungibleTokenUtils is CommonUtils, HederaTokenUtils {

    function _getSimpleHederaNftTokenInfo(
        string memory name,
        string memory symbol,
        address treasury
    ) internal returns (IHederaTokenService.TokenInfo memory tokenInfo) {
        IHederaTokenService.HederaToken memory token = _getSimpleHederaToken(name, symbol, treasury);
        tokenInfo.token = token;
    }

}
