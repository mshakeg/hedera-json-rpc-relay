// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

import 'hedera-smart-contracts/hts-precompile/HederaResponseCodes.sol';
import 'hedera-smart-contracts/hts-precompile/IHederaTokenService.sol';

contract HederaFungibleToken is ERC20 {
    IHederaTokenService.FungibleTokenInfo public fungibleTokenInfo;

    constructor(
        IHederaTokenService.FungibleTokenInfo memory _fungibleTokenInfo
    ) ERC20(_fungibleTokenInfo.tokenInfo.token.name, _fungibleTokenInfo.tokenInfo.token.symbol) {
        address treasury = _setFungibleTokenInfo(_fungibleTokenInfo);
        _mint(treasury, _fungibleTokenInfo.tokenInfo.totalSupply);
    }

    function _setFungibleTokenInfo(IHederaTokenService.FungibleTokenInfo memory _fungibleTokenInfo) internal returns (address treasury) {
        fungibleTokenInfo.tokenInfo.token.name = _fungibleTokenInfo.tokenInfo.token.name;
        fungibleTokenInfo.tokenInfo.token.symbol = _fungibleTokenInfo.tokenInfo.token.symbol;
        fungibleTokenInfo.tokenInfo.token.treasury = _fungibleTokenInfo.tokenInfo.token.treasury;

        treasury = _fungibleTokenInfo.tokenInfo.token.treasury;

        fungibleTokenInfo.tokenInfo.token.memo = _fungibleTokenInfo.tokenInfo.token.memo;
        fungibleTokenInfo.tokenInfo.token.tokenSupplyType = _fungibleTokenInfo.tokenInfo.token.tokenSupplyType;
        fungibleTokenInfo.tokenInfo.token.maxSupply = _fungibleTokenInfo.tokenInfo.token.maxSupply;
        fungibleTokenInfo.tokenInfo.token.freezeDefault = _fungibleTokenInfo.tokenInfo.token.freezeDefault;

        // Copy the tokenKeys array
        uint256 length = _fungibleTokenInfo.tokenInfo.token.tokenKeys.length;
        for (uint256 i = 0; i < length; i++) {
            fungibleTokenInfo.tokenInfo.token.tokenKeys.push(_fungibleTokenInfo.tokenInfo.token.tokenKeys[i]);
        }

        fungibleTokenInfo.tokenInfo.token.expiry.second = _fungibleTokenInfo.tokenInfo.token.expiry.second;
        fungibleTokenInfo.tokenInfo.token.expiry.autoRenewAccount = _fungibleTokenInfo
            .tokenInfo
            .token
            .expiry
            .autoRenewAccount;
        fungibleTokenInfo.tokenInfo.token.expiry.autoRenewPeriod = _fungibleTokenInfo
            .tokenInfo
            .token
            .expiry
            .autoRenewPeriod;

        fungibleTokenInfo.tokenInfo.totalSupply = _fungibleTokenInfo.tokenInfo.totalSupply;
        fungibleTokenInfo.tokenInfo.deleted = _fungibleTokenInfo.tokenInfo.deleted;
        fungibleTokenInfo.tokenInfo.defaultKycStatus = _fungibleTokenInfo.tokenInfo.defaultKycStatus;
        fungibleTokenInfo.tokenInfo.pauseStatus = _fungibleTokenInfo.tokenInfo.pauseStatus;

        // Handle copying of other arrays (fixedFees, fractionalFees, and royaltyFees) if needed

        fungibleTokenInfo.tokenInfo.ledgerId = _fungibleTokenInfo.tokenInfo.ledgerId;
        fungibleTokenInfo.decimals = _fungibleTokenInfo.decimals;
    }
}
