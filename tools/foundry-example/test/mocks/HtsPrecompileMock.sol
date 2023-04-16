// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'hedera-smart-contracts/hts-precompile/HederaResponseCodes.sol';
import 'hedera-smart-contracts/hts-precompile/IHederaTokenService.sol';
import 'hedera-smart-contracts/hts-precompile/KeyHelper.sol';
import './HederaFungibleToken.sol';
import '../../src/NoDelegateCall.sol';

contract HtsPrecompileMock is NoDelegateCall, IHederaTokenService, KeyHelper {
    address constant ADDRESS_ZERO = address(0);

    /// @dev only for Fungible tokens
    // Fungible token -> FungibleTokenInfo
    mapping(address => FungibleTokenInfo) internal _fungibleTokenInfos;
    // Fungible token -> keyType -> value e.g. 1 -> 0x123 means that the ADMIN is account 0x123
    mapping(address => mapping(uint => address)) internal _tokenKeys; /// @dev faster access then getting keys via FungibleTokenInfo#TokenInfo.HederaToken.tokenKeys[]; however only supports KeyValueType.CONTRACT_ID
    // Fungible token -> _isFungible
    mapping(address => bool) internal _isFungible;

    /// @dev only for NonFungibleToken
    // // NFT token -> NonFungibleTokenInfo
    mapping(address => NonFungibleTokenInfo) internal _nonFungibleTokenInfos;
    // // NFT token -> owner -> spender -> serialNumber -> isAllowed
    // mapping(address => mapping(address => mapping(address => mapping(uint256 => bool)))) internal _nftAllowances;
    // NFT token -> _isNonFungible
    mapping(address => bool) internal _isNonFungible;

    /// @dev common to both NFT and Fungible HTS tokens
    // HTS token -> account -> isAssociated
    mapping(address => mapping(address => bool)) internal _association;
    // HTS token -> account -> isKyced
    mapping(address => mapping(address => bool)) internal _kyc;
    // HTS token -> account -> isFrozen
    mapping(address => mapping(address => bool)) internal _frozen;

    modifier onlyHederaToken() {
        require(_isToken(msg.sender), 'NOT_HEDERA_TOKEN');
    }

    function _isToken(address token) internal view returns (bool) {
        return _isFungible[token] || _isNonFungible[token];
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

    function _hasTreasurySig(address token) internal view returns (bool validKey, bool noKey) {
        address key = _fungibleTokenInfos[token].tokenInfo.token.treasury;
        noKey = key == ADDRESS_ZERO;
        validKey = _isAccountOriginOrSender(key);
    }

    function _hasAdminKeySig(address token) internal view returns (bool validKey, bool noKey) {
        address key = getKey(token, KeyHelper.KeyType.ADMIN);
        noKey = key == ADDRESS_ZERO;
        validKey = _isAccountOriginOrSender(key);
    }

    function _hasKycKeySig(address token) internal view returns (bool validKey, bool noKey) {
        address key = getKey(token, KeyHelper.KeyType.KYC);
        noKey = key == ADDRESS_ZERO;
        validKey = _isAccountOriginOrSender(key);
    }

    function _hasFreezeKeySig(address token) internal view returns (bool validKey, bool noKey) {
        address key = getKey(token, KeyHelper.KeyType.FREEZE);
        noKey = key == ADDRESS_ZERO;
        validKey = _isAccountOriginOrSender(key);
    }

    function _hasWipeKeySig(address token) internal view returns (bool validKey, bool noKey) {
        address key = getKey(token, KeyHelper.KeyType.WIPE);
        noKey = key == ADDRESS_ZERO;
        validKey = _isAccountOriginOrSender(key);
    }

    function _hasSupplyKeySig(address token) internal view returns (bool validKey, bool noKey) {
        address key = getKey(token, KeyHelper.KeyType.SUPPLY);
        noKey = key == ADDRESS_ZERO;
        validKey = _isAccountOriginOrSender(key);
    }

    function _hasFeeScheduleKeySig(address token) internal view returns (bool validKey, bool noKey) {
        address key = getKey(token, KeyHelper.KeyType.FEE);
        noKey = key == ADDRESS_ZERO;
        validKey = _isAccountOriginOrSender(key);
    }

    function _hasPauseKeySig(address token) internal view returns (bool validKey, bool noKey) {
        address key = getKey(token, KeyHelper.KeyType.PAUSE);
        noKey = key == ADDRESS_ZERO;
        validKey = _isAccountOriginOrSender(key);
    }

    function _setFungibleTokenInfo(
        FungibleTokenInfo memory fungibleTokenInfo
    ) internal returns (address treasury) {
        _fungibleTokenInfos[msg.sender].tokenInfo.token.name = fungibleTokenInfo.tokenInfo.token.name;
        _fungibleTokenInfos[msg.sender].tokenInfo.token.symbol = fungibleTokenInfo.tokenInfo.token.symbol;
        _fungibleTokenInfos[msg.sender].tokenInfo.token.treasury = fungibleTokenInfo.tokenInfo.token.treasury;

        treasury = fungibleTokenInfo.tokenInfo.token.treasury;

        _fungibleTokenInfos[msg.sender].tokenInfo.token.memo = fungibleTokenInfo.tokenInfo.token.memo;
        _fungibleTokenInfos[msg.sender].tokenInfo.token.tokenSupplyType = fungibleTokenInfo
            .tokenInfo
            .token
            .tokenSupplyType;
        _fungibleTokenInfos[msg.sender].tokenInfo.token.maxSupply = fungibleTokenInfo.tokenInfo.token.maxSupply;
        _fungibleTokenInfos[msg.sender].tokenInfo.token.freezeDefault = fungibleTokenInfo.tokenInfo.token.freezeDefault;

        // Copy the tokenKeys array
        uint256 length = fungibleTokenInfo.tokenInfo.token.tokenKeys.length;
        for (uint256 i = 0; i < length; i++) {
            TokenKey memory tokenKey = fungibleTokenInfo.tokenInfo.token.tokenKeys[i];
            _fungibleTokenInfos[msg.sender].tokenInfo.token.tokenKeys.push(tokenKey);

            /// @dev contractId can in fact be any address including an EOA address
            ///      The KeyHelper lists 5 types for KeyValueType; however only CONTRACT_ID is considered
            _tokenKeys[msg.sender][tokenKey.keyType] = tokenKey.key.contractId;
        }

        _fungibleTokenInfos[msg.sender].tokenInfo.token.expiry.second = fungibleTokenInfo.tokenInfo.token.expiry.second;
        _fungibleTokenInfos[msg.sender].tokenInfo.token.expiry.autoRenewAccount = fungibleTokenInfo
            .tokenInfo
            .token
            .expiry
            .autoRenewAccount;
        _fungibleTokenInfos[msg.sender].tokenInfo.token.expiry.autoRenewPeriod = fungibleTokenInfo
            .tokenInfo
            .token
            .expiry
            .autoRenewPeriod;

        _fungibleTokenInfos[msg.sender].tokenInfo.totalSupply = fungibleTokenInfo.tokenInfo.totalSupply;
        _fungibleTokenInfos[msg.sender].tokenInfo.deleted = fungibleTokenInfo.tokenInfo.deleted;
        _fungibleTokenInfos[msg.sender].tokenInfo.defaultKycStatus = fungibleTokenInfo.tokenInfo.defaultKycStatus;
        _fungibleTokenInfos[msg.sender].tokenInfo.pauseStatus = fungibleTokenInfo.tokenInfo.pauseStatus;

        // Handle copying of other arrays (fixedFees, fractionalFees, and royaltyFees) if needed

        _fungibleTokenInfos[msg.sender].tokenInfo.ledgerId = fungibleTokenInfo.tokenInfo.ledgerId;
        _fungibleTokenInfos[msg.sender].decimals = fungibleTokenInfo.decimals;
    }

    /// @dev the following internal _precheck functions are called in either of the following 2 scenarios:
    ///      1. before the HtsPrecompileMock calls any of the HederaFungibleToken or HederaNonFungibleToken functions that specify the onlyHtsPrecompile modifier
    ///      2. in any of HtsPrecompileMock functions that specifies the onlyHederaToken modifier which is only callable by a HederaFungibleToken or HederaNonFungibleToken contract

    function _precheckApprove() internal {

    }

    function _precheckMint() internal {

    }

    function _precheckBurn() internal {

    }

    function _precheckTransfer() internal {

    }

    function preApprove() external onlyHederaToken {

    }

    function preMint() external onlyHederaToken {

    }

    function preBurn() external onlyHederaToken {

    }

    function preTransfer() external onlyHederaToken {

    }

    /// @dev register HederaFungibleToken; msg.sender is the HederaFungibleToken
    ///      can be called by any contract; however assumes msg.sender is a HederaFungibleToken
    function registerHederaFungibleToken(FungibleTokenInfo memory fungibleTokenInfo) external {
        _isFungible[msg.sender] = true;
        _setFungibleTokenInfo(fungibleTokenInfo);
    }

    /// @dev register HederaNonFungibleToken; msg.sender is the HederaNonFungibleToken
    ///      can be called by any contract; however assumes msg.sender is a HederaNonFungibleToken
    function registerHederaNonFungibleToken(
        NonFungibleTokenInfo memory nonFungibleTokenInfo
    ) external {}

    // IHederaTokenService public/external view functions:
    function getApproved(
        address token,
        uint256 serialNumber
    ) external view returns (int64 responseCode, address approved) {
        // TODO: NonFungibleToken
    }

    function getFungibleTokenInfo(
        address token
    ) external view returns (int64 responseCode, FungibleTokenInfo memory fungibleTokenInfo) {
        fungibleTokenInfo = _fungibleTokenInfos[token];
    }

    function getNonFungibleTokenInfo(
        address token,
        int64 serialNumber
    ) external view returns (int64 responseCode, NonFungibleTokenInfo memory nonFungibleTokenInfo) {
        // TODO: NonFungibleToken
    }

    function getTokenCustomFees(
        address token
    )
        external
        view
        returns (
            int64 responseCode,
            FixedFee[] memory fixedFees,
            FractionalFee[] memory fractionalFees,
            RoyaltyFee[] memory royaltyFees
        )
    {
        responseCode = HederaResponseCodes.SUCCESS;
        fixedFees = _fungibleTokenInfos[token].tokenInfo.fixedFees;
        fractionalFees = _fungibleTokenInfos[token].tokenInfo.fractionalFees;
        royaltyFees = _fungibleTokenInfos[token].tokenInfo.royaltyFees;
    }

    function getTokenDefaultFreezeStatus(
        address token
    ) external view returns (int64 responseCode, bool defaultFreezeStatus) {
        responseCode = HederaResponseCodes.SUCCESS;
        defaultFreezeStatus = _fungibleTokenInfos[token].tokenInfo.token.freezeDefault;
    }

    function getTokenDefaultKycStatus(
        address token
    ) external view returns (int64 responseCode, bool defaultKycStatus) {
        responseCode = HederaResponseCodes.SUCCESS;
        defaultKycStatus = _fungibleTokenInfos[token].tokenInfo.defaultKycStatus;
    }

    function getTokenExpiryInfo(address token) external view returns (int64 responseCode, Expiry memory expiry) {
        if (!_isToken(token)) {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        } else {
            if (_isFungible[token]) {
                expiry = _fungibleTokenInfos[token].tokenInfo.token.expiry;
                responseCode = HederaResponseCodes.SUCCESS;
            } else {
                // TODO: NonFungibleToken
            }
        }
    }

    function getTokenInfo(address token) external view returns (int64 responseCode, TokenInfo memory tokenInfo) {
        if (!_isToken(token)) {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        } else {
            if (_isFungible[token]) {
                tokenInfo = _fungibleTokenInfos[token].tokenInfo;
                responseCode = HederaResponseCodes.SUCCESS;
            } else {
                // TODO: NonFungibleToken
            }
        }
    }

    function getTokenKey(address token, uint keyType) external view returns (int64 responseCode, KeyValue memory key) {
        if (!_isToken(token)) {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        } else {
            if (_isFungible[token]) {
                /// @dev the key can be retrieved using either of the following method
                // method 1: gas inefficient
                // uint256 length = _fungibleTokenInfos[token].tokenInfo.token.tokenKeys.length;
                // for (uint256 i = 0; i < length; i++) {
                //     IHederaTokenService.TokenKey memory tokenKey = _fungibleTokenInfos[token].tokenInfo.token.tokenKeys[i];
                //     if (tokenKey.keyType == keyType) {
                //         key = tokenKey.key;
                //         break;
                //     }
                // }

                // method 2: more gas efficient; however currently only considers contractId
                address keyValue = _tokenKeys[token][keyType];
                key.contractId = keyValue;
                responseCode = HederaResponseCodes.SUCCESS;
            } else {
                // TODO: NonFungibleToken
            }
        }
    }

    function getTokenType(address token) external view returns (int64 responseCode, int32 tokenType) {
        bool isFungibleToken = _isFungible[token];
        bool isNonFungibleToken = _isNonFungible[token];
        if (!isFungibleToken && !isNonFungibleToken) {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        } else {
            tokenType = isFungibleToken ? int8(0) : int8(1);
        }
    }

    function grantTokenKyc(address token, address account) external returns (int64 responseCode) {
        if (!_isFungible[token] && !_isNonFungible[token]) {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        } else if (_kyc[token][account]) {
            responseCode = HederaResponseCodes.SUCCESS; /// @dev if already KYCed return SUCCESS; no code similar to TOKEN_ALREADY_ASSOCIATED_TO_ACCOUNT
        } else {
            (bool validKey, bool noKey) = _hasKycKeySig(token);

            if (noKey) {
                responseCode = HederaResponseCodes.TOKEN_HAS_NO_KYC_KEY;
            } else if (!validKey) {
                responseCode = HederaResponseCodes.INVALID_KYC_KEY;
            } else {
                responseCode = HederaResponseCodes.SUCCESS;
                _kyc[token][account] = true;
            }
        }
    }

    /// @dev Applicable ONLY to NFT Tokens; accessible via IERC721
    function isApprovedForAll(
        address token,
        address owner,
        address operator
    ) external view returns (int64 responseCode, bool approved) {}

    function isFrozen(address token, address account) external view returns (int64 responseCode, bool frozen) {
        if (!_isFungible[token] && !_isNonFungible[token]) {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        } else if (getKey(token, KeyHelper.KeyType.FREEZE) == ADDRESS_ZERO) {
            responseCode = HederaResponseCodes.TOKEN_HAS_NO_FREEZE_KEY;
        } else {
            responseCode = HederaResponseCodes.SUCCESS;
            frozen = _frozen[token][account];
        }
    }

    function isKyc(address token, address account) external view returns (int64 responseCode, bool kycGranted) {
        if (!_isFungible[token] && !_isNonFungible[token]) {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        } else if (getKey(token, KeyHelper.KeyType.KYC) == ADDRESS_ZERO) {
            responseCode = HederaResponseCodes.TOKEN_HAS_NO_KYC_KEY;
        } else {
            responseCode = HederaResponseCodes.SUCCESS;
            kycGranted = _kyc[token][account];
        }
    }

    function isToken(address token) public view returns (int64 responseCode, bool isToken) {
        isToken = _isToken(token);
        responseCode = isToken ? HederaResponseCodes.SUCCESS : HederaResponseCodes.INVALID_TOKEN_ID;
    }

    function allowance(
        address token,
        address owner,
        address spender
    ) external view returns (int64 responseCode, uint256 allowance) {
        if (!_isFungible[token]) {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        } else {
            responseCode = HederaResponseCodes.SUCCESS;
            allowance = HederaFungibleToken(token).allowance(owner, spender);
        }
    }

    // Additional(not in IHederaTokenService) public/external view functions:
    function getKey(address token, KeyHelper.KeyType keyType) public view returns (address keyOwner) {
        keyOwner = _tokenKeys[token][keyTypes[keyType]];
    }

    // IHederaTokenService public/external state-changing functions:
    function createFungibleToken(
        HederaToken memory token,
        int64 initialTotalSupply,
        int32 decimals
    ) external payable noDelegateCall returns (int64 responseCode, address tokenAddress) {
        // TODO: do precheck validation on token
        FungibleTokenInfo memory fungibleTokenInfo;
        TokenInfo memory tokenInfo;

        tokenInfo.token = token;
        tokenInfo.totalSupply = initialTotalSupply;

        fungibleTokenInfo.decimals = decimals;
        fungibleTokenInfo.tokenInfo = tokenInfo;

        /// @dev no need to register newly created HederaFungibleToken in this context as the constructor will call HtsPrecompileMock#registerHederaFungibleToken
        HederaFungibleToken hederaFungibleToken = new HederaFungibleToken(fungibleTokenInfo);
    }

    function createNonFungibleToken(
        HederaToken memory token
    ) external payable noDelegateCall returns (int64 responseCode, address tokenAddress) {
        // TODO: NonFungibleToken
        // TODO: do validation on token
    }

    function createFungibleTokenWithCustomFees(
        HederaToken memory token,
        int64 initialTotalSupply,
        int32 decimals,
        FixedFee[] memory fixedFees,
        FractionalFee[] memory fractionalFees
    ) external payable noDelegateCall returns (int64 responseCode, address tokenAddress) {
        // TODO: do validation on token
        FungibleTokenInfo memory fungibleTokenInfo;
        TokenInfo memory tokenInfo;

        tokenInfo.token = token;
        tokenInfo.totalSupply = initialTotalSupply;
        tokenInfo.fixedFees = fixedFees;
        tokenInfo.fractionalFees = fractionalFees;

        fungibleTokenInfo.decimals = decimals;
        fungibleTokenInfo.tokenInfo = tokenInfo;

        /// @dev no need to register newly created HederaFungibleToken in this context as the constructor will call HtsPrecompileMock#registerHederaFungibleToken
        HederaFungibleToken hederaFungibleToken = new HederaFungibleToken(fungibleTokenInfo);
    }

    function createNonFungibleTokenWithCustomFees(
        HederaToken memory token,
        FixedFee[] memory fixedFees,
        RoyaltyFee[] memory royaltyFees
    ) external payable noDelegateCall returns (int64 responseCode, address tokenAddress) {
        // TODO: NonFungibleToken
    }

    function cryptoTransfer(
        TransferList memory transferList,
        TokenTransferList[] memory tokenTransfers
    ) external noDelegateCall returns (int64 responseCode) {}

    function deleteToken(address token) external noDelegateCall returns (int64 responseCode) {}

    function approve(
        address token,
        address spender,
        uint256 amount
    ) external noDelegateCall returns (int64 responseCode) {
        if (!_isFungible[token]) {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        } else if (!_association[token][msg.sender] || !_association[token][spender]) {
            responseCode = HederaResponseCodes.TOKEN_NOT_ASSOCIATED_TO_ACCOUNT;
        } else {
            HederaFungibleToken(token).approveRequestFromHtsPrecompile(msg.sender, spender, amount);
            responseCode = HederaResponseCodes.SUCCESS;
        }
    }

    function approveNFT(
        address token,
        address approved,
        uint256 serialNumber
    ) external noDelegateCall returns (int64 responseCode) {
        // TODO: NonFungibleToken
        // if (!_isNonFungible[token]) {
        //     responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        // } else if (!_association[token][msg.sender] || !_association[token][approved]) {
        //     responseCode = HederaResponseCodes.TOKEN_NOT_ASSOCIATED_TO_ACCOUNT;
        // } else {
        //     _allowances[token][msg.sender][approved][serialNumber] = true;
        //     responseCode = HederaResponseCodes.SUCCESS;
        // }
    }

    function associateToken(address account, address token) public noDelegateCall returns (int64 responseCode) {
        if (!_isFungible[token] && !_isNonFungible[token]) {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        } else if (_association[account][token]) {
            responseCode = HederaResponseCodes.TOKEN_ALREADY_ASSOCIATED_TO_ACCOUNT;
        } else {
            responseCode = HederaResponseCodes.SUCCESS;
            _association[account][token] = true;
        }
    }

    function associateTokens(
        address account,
        address[] memory tokens
    ) external noDelegateCall returns (int64 responseCode) {
        responseCode = HederaResponseCodes.SUCCESS;
        for (uint256 i = 0; i < tokens.length; i++) {
            int64 tokenResponseCode = associateToken(account, tokens[i]);
            if (tokenResponseCode != HederaResponseCodes.SUCCESS) {
                responseCode = tokenResponseCode;
                break;
            }
        }
        return responseCode;
    }

    function dissociateTokens(
        address account,
        address[] memory tokens
    ) external noDelegateCall returns (int64 responseCode) {
        responseCode = HederaResponseCodes.SUCCESS;
        for (uint256 i = 0; i < tokens.length; i++) {
            int64 tokenResponseCode = dissociateToken(account, tokens[i]);
            if (tokenResponseCode != HederaResponseCodes.SUCCESS) {
                responseCode = tokenResponseCode;
                break;
            }
        }
        return responseCode;
    }

    function dissociateToken(address account, address token) public noDelegateCall returns (int64 responseCode) {
        if (!_isFungible[token] && !_isNonFungible[token]) {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        } else if (!_association[account][token]) {
            responseCode = HederaResponseCodes.TOKEN_NOT_ASSOCIATED_TO_ACCOUNT;
        } else {
            responseCode = HederaResponseCodes.SUCCESS;
            _association[account][token] = false;
        }
    }

    function freezeToken(address token, address account) external noDelegateCall returns (int64 responseCode) {}

    function mintToken(
        address token,
        int64 amount,
        bytes[] memory metadata
    ) external noDelegateCall returns (int64 responseCode, int64 newTotalSupply, int64[] memory serialNumbers) {
        bool isFungible = _isFungible[token];
        bool isNonFungible = _isNonFungible[token];
        if (isFungible) {
            (bool validKey, bool noKey) = _hasSupplyKeySig(token);

            if (noKey) {
                responseCode = HederaResponseCodes.TOKEN_HAS_NO_SUPPLY_KEY;
            } else if (!validKey) {
                responseCode = HederaResponseCodes.INVALID_SUPPLY_KEY;
            } else {
                HederaFungibleToken(token).mintRequestFromHtsPrecompile(amount);
                responseCode = HederaResponseCodes.SUCCESS;
            }
        } else if (isNonFungible) {
            // TODO: NonFungibleToken
        } else {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        }
    }

    function burnToken(
        address token,
        int64 amount,
        int64[] memory serialNumbers
    ) external noDelegateCall returns (int64 responseCode, int64 newTotalSupply) {
        bool isFungible = _isFungible[token];
        bool isNonFungible = _isNonFungible[token];

        if (_isFungible[token]) {
            (bool validKey, bool noKey) = _hasTreasurySig(token);

            if (noKey || !validKey) { /// @dev noKey should always be false as a token must have a treasury account; however use INVALID_TREASURY_ACCOUNT_FOR_TOKEN if treasury has been deleted
                responseCode = HederaResponseCodes.AUTHORIZATION_FAILED;
            } else {
                HederaFungibleToken(token).burnRequestFromHtsPrecompile(amount);
                responseCode = HederaResponseCodes.SUCCESS;
            }

        } else if (_isNonFungible[token]) {
            // TODO: NonFungibleToken
            NonFungibleTokenInfo memory nonFungibleTokenInfo = _nonFungibleTokenInfos[token];
        } else {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        }
    }

    function pauseToken(address token) external noDelegateCall returns (int64 responseCode) {}

    function revokeTokenKyc(address token, address account) external noDelegateCall returns (int64 responseCode) {}

    function setApprovalForAll(
        address token,
        address operator,
        bool approved
    ) external noDelegateCall returns (int64 responseCode) {}

    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) external noDelegateCall returns (int64 responseCode) {}

    function transferFromNFT(
        address token,
        address from,
        address to,
        uint256 serialNumber
    ) external noDelegateCall returns (int64 responseCode) {
        // TODO: NonFungibleToken
    }

    function transferNFT(
        address token,
        address sender,
        address recipient,
        int64 serialNumber
    ) external noDelegateCall returns (int64 responseCode) {
        // TODO: NonFungibleToken
    }

    function transferNFTs(
        address token,
        address[] memory sender,
        address[] memory receiver,
        int64[] memory serialNumber
    ) external noDelegateCall returns (int64 responseCode) {
        // TODO: NonFungibleToken
    }

    function transferToken(
        address token,
        address sender,
        address recipient,
        int64 amount
    ) external noDelegateCall returns (int64 responseCode) {}

    function transferTokens(
        address token,
        address[] memory accountId,
        int64[] memory amount
    ) external noDelegateCall returns (int64 responseCode) {}

    function unfreezeToken(address token, address account) external noDelegateCall returns (int64 responseCode) {}

    function unpauseToken(address token) external noDelegateCall returns (int64 responseCode) {}

    function updateTokenExpiryInfo(address token, Expiry memory expiryInfo) external noDelegateCall returns (int64 responseCode) {}

    function updateTokenInfo(address token, HederaToken memory tokenInfo) external noDelegateCall returns (int64 responseCode) {}

    function updateTokenKeys(address token, TokenKey[] memory keys) external noDelegateCall returns (int64 responseCode) {}

    function wipeTokenAccount(address token, address account, int64 amount) external noDelegateCall returns (int64 responseCode) {}

    function wipeTokenAccountNFT(
        address token,
        address account,
        int64[] memory serialNumbers
    ) external noDelegateCall returns (int64 responseCode) {
        // TODO: NonFungibleToken
    }

    function redirectForToken(address token, bytes memory encodedFunctionSelector) external noDelegateCall {}

    // Additional(not in IHederaTokenService) public/external state-changing functions:
}
