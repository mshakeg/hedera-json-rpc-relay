// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

import 'hedera-smart-contracts/hts-precompile/HederaResponseCodes.sol';
import 'hedera-smart-contracts/hts-precompile/IHederaTokenService.sol';
import 'hedera-smart-contracts/hts-precompile/KeyHelper.sol';

contract HederaFungibleToken is ERC20, KeyHelper {
    IHederaTokenService.FungibleTokenInfo public fungibleTokenInfo;
    // key -> value e.g. 1 -> 0x123 means that the ADMIN is account 0x123
    mapping(uint => address) internal tokenKeys;

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
            IHederaTokenService.TokenKey memory tokenKey = _fungibleTokenInfo.tokenInfo.token.tokenKeys[i];
            fungibleTokenInfo.tokenInfo.token.tokenKeys.push(tokenKey);

            /// @dev contractId can in fact be any address including an EOA address
            ///      The KeyHelper lists 5 types for KeyValueType; however only CONTRACT_ID is considered
            tokenKeys[tokenKey.keyType] = tokenKey.key.contractId;
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

    function _isAccountOriginOrSender(address account) internal view returns (bool) {
        return _isAccountOrigin(account) || _isAccountSender(msg.sender);
    }

    function _isAccountOrigin(address account) internal view returns (bool) {
        return account == tx.origin;
    }

    function _isAccountSender(address account) internal view returns (bool) {
        return account == msg.sender;
    }

    function _hasTreasurySig() internal view returns (bool) {
        return _isAccountOriginOrSender(fungibleTokenInfo.tokenInfo.token.treasury);
    }

    function _hasAdminKeySig() internal view returns (bool) {
        return _isAccountOriginOrSender(getKey(KeyHelper.KeyType.ADMIN));
    }

    function _hasKycKeySig() internal view returns (bool) {
        return _isAccountOriginOrSender(getKey(KeyHelper.KeyType.KYC));
    }

    function _hasFreezeKeySig() internal view returns (bool) {
        return _isAccountOriginOrSender(getKey(KeyHelper.KeyType.FREEZE));
    }

    function _hasWipeKeySig() internal view returns (bool) {
        return _isAccountOriginOrSender(getKey(KeyHelper.KeyType.WIPE));
    }

    function _hasSupplyKeySig() internal view returns (bool) {
        return _isAccountOriginOrSender(getKey(KeyHelper.KeyType.SUPPLY));
    }

    function _hasFeeScheduleKeySig() internal view returns (bool) {
        return _isAccountOriginOrSender(getKey(KeyHelper.KeyType.FEE));
    }

    function _hasPauseKeySig() internal view returns (bool) {
        return _isAccountOriginOrSender(getKey(KeyHelper.KeyType.PAUSE));
    }

    // public/external state-changing functions
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    // public/external view functions
    function getKey(KeyHelper.KeyType keyType) public view returns (address keyOwner) {
        keyOwner = tokenKeys[keyTypes[keyType]];
    }
}
