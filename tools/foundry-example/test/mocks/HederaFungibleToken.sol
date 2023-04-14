// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

import 'hedera-smart-contracts/hts-precompile/HederaResponseCodes.sol';
import 'hedera-smart-contracts/hts-precompile/IHederaTokenService.sol';
import 'hedera-smart-contracts/hts-precompile/KeyHelper.sol';

// TODO: create a tighter coupling between instances of HederaFungibleToken and the HtsPrecompileMock contract
//       such that if a HederaFungibleToken contract is created directly it's registered with the HtsPrecompileMock contract
//       and if an action is attempted directly via the HederaFungibleToken contract it first goes through the HtsPrecompileMock contract
//       and if an action goes through the HtsPrecompileMock contract then it ultimately calls the HederaFungibleToken contract
//       HederaFungibleToken contract should store state related to ERC20 and do validation related to ERC20
//       HtsPrecompileMock contract should store extra state related to the HTS and do validation related to HTS business logic
//       HederaFungibleToken contract should expose special methods only callable by the precompile contract
//       Doing it like this would remove the need for the {grant|revoke}HtsPrecompilePermissions flow

contract HederaFungibleToken is ERC20, KeyHelper {

    address internal HTS_PRECOMPILE = address(0x167);

    IHederaTokenService.FungibleTokenInfo public fungibleTokenInfo;
    // key -> value e.g. 1 -> 0x123 means that the ADMIN is account 0x123
    mapping(uint => address) internal _tokenKeys;

    /// @dev if the HtsPrecompile(0x167) calls a HederaFungibleToken and if address has granted the precompile permissions then allow the precompile to execute HTS actions
    ///      In tests you should grant and revoke actions to the HTS Precompile immediately before and immediately after the main action; i.e. only grant permissions as required
    mapping(address => bool) public htsPrecompileCallPermissions;

    // account -> isAssociated with this token i.e. address(this)
    mapping(address => bool) public isAssociated;

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
            _tokenKeys[tokenKey.keyType] = tokenKey.key.contractId;
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

    function _isAccountOriginOrSenderOrPermittedHtsPrecompile(address account) internal view returns (bool) {
        return _isAccountOriginOrSender(account) || _isPermittedHtsPrecompile(account);
    }

    function _isPermittedHtsPrecompile(address account) internal view returns (bool) {
        return htsPrecompileCallPermissions[account] && msg.sender == HTS_PRECOMPILE;
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

    // public/external state-changing functions:

    // TODO: only allow the contract deployer or master account to call this function
    function grantHtsPrecompilePermissions(address account) external {
        htsPrecompileCallPermissions[account] = true;
        _approve(account, HTS_PRECOMPILE, type(uint).max);
    }

    // TODO: only allow the contract deployer or master account to call this function
    function revokeHtsPrecompilePermissions(address account) external {
        htsPrecompileCallPermissions[account] = false;
        _approve(account, HTS_PRECOMPILE, 0);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    function associate(address account) public returns (int64 responseCode) {
        if (_isAccountOriginOrSenderOrPermittedHtsPrecompile(account)) {

            if (isAssociated[account]) {
                isAssociated[account] = true;
                responseCode = HederaResponseCodes.SUCCESS;
            } else {
                responseCode = HederaResponseCodes.TOKEN_ALREADY_ASSOCIATED_TO_ACCOUNT;
            }

        } else {
            responseCode = HederaResponseCodes.INVALID_SIGNATURE;
        }
    }

    // public/external view functions:
    function getKey(KeyHelper.KeyType keyType) public view returns (address keyOwner) {
        keyOwner = _tokenKeys[keyTypes[keyType]];
    }
}
