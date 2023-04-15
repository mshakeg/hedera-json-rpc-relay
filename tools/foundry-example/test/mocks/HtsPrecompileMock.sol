// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'hedera-smart-contracts/hts-precompile/HederaResponseCodes.sol';
import 'hedera-smart-contracts/hts-precompile/IHederaTokenService.sol';
import 'hedera-smart-contracts/hts-precompile/KeyHelper.sol';
import './HederaFungibleToken.sol';

contract HtsPrecompileMock is IHederaTokenService, KeyHelper {
    address constant ADDRESS_ZERO = address(0);

    /// @dev only for Fungible tokens
    // Fungible token -> FungibleTokenInfo
    mapping(address => IHederaTokenService.FungibleTokenInfo) public fungibleTokenInfo;
    // Fungible token -> key -> value e.g. 1 -> 0x123 means that the ADMIN is account 0x123
    mapping(address => mapping(uint => address)) internal _tokenKeys;
    // Fungible token -> _isFungible
    mapping(address => bool) internal _isFungible;

    // // Fungible token -> owner -> spender -> allowance
    // mapping(address => mapping(address => mapping(address => uint256))) internal _allowances;
    // // Fungible token -> FungibleTokenInfo
    // mapping(address => FungibleTokenInfo) _fungibleTokenInfo;
    // // Fungible token -> account -> balance
    // mapping(address => mapping(address => uint256)) _fungibleBalance;

    /// @dev only for NFT tokens
    // NFT token -> _isNonFungible
    mapping(address => bool) internal _isNonFungible;
    // // NFT token -> owner -> spender -> serialNumber -> isAllowed
    // mapping(address => mapping(address => mapping(address => mapping(uint256 => bool)))) internal _nftAllowances;
    // // NFT token -> NonFungibleTokenInfo
    // mapping(address => NonFungibleTokenInfo) _nonFungibleTokenInfo;
    // // NFT token -> account -> serialNumber -> exists
    // mapping(address => mapping(address => uint256)) _nftBalance;

    /// @dev common to both NFT and Fungible HTS tokens
    // HTS token -> account -> isAssociated
    mapping(address => mapping(address => bool)) internal _association;
    // HTS token -> account -> isKyced
    mapping(address => mapping(address => bool)) internal _kyc;
    // HTS token -> account -> isFrozen
    mapping(address => mapping(address => bool)) internal _frozen;

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
        address key = fungibleTokenInfo[token].tokenInfo.token.treasury;
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
        IHederaTokenService.FungibleTokenInfo memory _fungibleTokenInfo
    ) internal returns (address treasury) {
        fungibleTokenInfo[msg.sender].tokenInfo.token.name = _fungibleTokenInfo.tokenInfo.token.name;
        fungibleTokenInfo[msg.sender].tokenInfo.token.symbol = _fungibleTokenInfo.tokenInfo.token.symbol;
        fungibleTokenInfo[msg.sender].tokenInfo.token.treasury = _fungibleTokenInfo.tokenInfo.token.treasury;

        treasury = _fungibleTokenInfo.tokenInfo.token.treasury;

        fungibleTokenInfo[msg.sender].tokenInfo.token.memo = _fungibleTokenInfo.tokenInfo.token.memo;
        fungibleTokenInfo[msg.sender].tokenInfo.token.tokenSupplyType = _fungibleTokenInfo
            .tokenInfo
            .token
            .tokenSupplyType;
        fungibleTokenInfo[msg.sender].tokenInfo.token.maxSupply = _fungibleTokenInfo.tokenInfo.token.maxSupply;
        fungibleTokenInfo[msg.sender].tokenInfo.token.freezeDefault = _fungibleTokenInfo.tokenInfo.token.freezeDefault;

        // Copy the tokenKeys array
        uint256 length = _fungibleTokenInfo.tokenInfo.token.tokenKeys.length;
        for (uint256 i = 0; i < length; i++) {
            IHederaTokenService.TokenKey memory tokenKey = _fungibleTokenInfo.tokenInfo.token.tokenKeys[i];
            fungibleTokenInfo[msg.sender].tokenInfo.token.tokenKeys.push(tokenKey);

            /// @dev contractId can in fact be any address including an EOA address
            ///      The KeyHelper lists 5 types for KeyValueType; however only CONTRACT_ID is considered
            _tokenKeys[msg.sender][tokenKey.keyType] = tokenKey.key.contractId;
        }

        fungibleTokenInfo[msg.sender].tokenInfo.token.expiry.second = _fungibleTokenInfo.tokenInfo.token.expiry.second;
        fungibleTokenInfo[msg.sender].tokenInfo.token.expiry.autoRenewAccount = _fungibleTokenInfo
            .tokenInfo
            .token
            .expiry
            .autoRenewAccount;
        fungibleTokenInfo[msg.sender].tokenInfo.token.expiry.autoRenewPeriod = _fungibleTokenInfo
            .tokenInfo
            .token
            .expiry
            .autoRenewPeriod;

        fungibleTokenInfo[msg.sender].tokenInfo.totalSupply = _fungibleTokenInfo.tokenInfo.totalSupply;
        fungibleTokenInfo[msg.sender].tokenInfo.deleted = _fungibleTokenInfo.tokenInfo.deleted;
        fungibleTokenInfo[msg.sender].tokenInfo.defaultKycStatus = _fungibleTokenInfo.tokenInfo.defaultKycStatus;
        fungibleTokenInfo[msg.sender].tokenInfo.pauseStatus = _fungibleTokenInfo.tokenInfo.pauseStatus;

        // Handle copying of other arrays (fixedFees, fractionalFees, and royaltyFees) if needed

        fungibleTokenInfo[msg.sender].tokenInfo.ledgerId = _fungibleTokenInfo.tokenInfo.ledgerId;
        fungibleTokenInfo[msg.sender].decimals = _fungibleTokenInfo.decimals;
    }

    /// @dev register HederaFungibleToken; msg.sender is the HederaFungibleToken
    ///      can be called by any contract; however assumes msg.sender is a HederaFungibleToken
    function registerHederaFungibleToken(IHederaTokenService.FungibleTokenInfo memory _fungibleTokenInfo) external {
        _setFungibleTokenInfo(_fungibleTokenInfo);
    }

    /// @dev register HederaNonFungibleToken; msg.sender is the HederaNonFungibleToken
    ///      can be called by any contract; however assumes msg.sender is a HederaNonFungibleToken
    function registerHederaNonFungibleToken(
        IHederaTokenService.NonFungibleTokenInfo memory _nonFungibleTokenInfo
    ) external {}

    // IHederaTokenService public/external view functions:
    function getApproved(
        address token,
        uint256 serialNumber
    ) external view returns (int64 responseCode, address approved) {}

    function getFungibleTokenInfo(
        address token
    ) external view returns (int64 responseCode, FungibleTokenInfo memory fungibleTokenInfo) {}

    function getNonFungibleTokenInfo(
        address token,
        int64 serialNumber
    ) external view returns (int64 responseCode, NonFungibleTokenInfo memory nonFungibleTokenInfo) {}

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
    {}

    function getTokenDefaultFreezeStatus(
        address token
    ) external view returns (int64 responseCode, bool defaultFreezeStatus) {}

    function getTokenDefaultKycStatus(
        address token
    ) external view returns (int64 responseCode, bool defaultKycStatus) {}

    function getTokenExpiryInfo(address token) external view returns (int64 responseCode, Expiry memory expiry) {}

    function getTokenInfo(address token) external view returns (int64 responseCode, TokenInfo memory tokenInfo) {}

    function getTokenKey(address token, uint keyType) external view returns (int64 responseCode, KeyValue memory key) {}

    function getTokenType(address token) external view returns (int64 responseCode, int32 tokenType) {
        bool isFungibleToken = _isFungible[token];
        bool isNonFungibleToken = _isNonFungible[token];
        if (!isFungibleToken && !isNonFungibleToken) {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        }

        tokenType = isFungibleToken ? int8(0) : int8(1);
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

    function isToken(address token) external view returns (int64 responseCode, bool isToken) {
        if (!_isFungible[token] && !_isNonFungible[token]) {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        } else {
            responseCode = HederaResponseCodes.SUCCESS;
            isToken = true;
        }
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
    ) external payable returns (int64 responseCode, address tokenAddress) {}

    function createNonFungibleToken(
        HederaToken memory token
    ) external payable returns (int64 responseCode, address tokenAddress) {}

    function createNonFungibleTokenWithCustomFees(
        HederaToken memory token,
        FixedFee[] memory fixedFees,
        RoyaltyFee[] memory royaltyFees
    ) external payable returns (int64 responseCode, address tokenAddress) {}

    function createFungibleTokenWithCustomFees(
        HederaToken memory token,
        int64 initialTotalSupply,
        int32 decimals,
        FixedFee[] memory fixedFees,
        FractionalFee[] memory fractionalFees
    ) external payable returns (int64 responseCode, address tokenAddress) {}

    function cryptoTransfer(
        TransferList memory transferList,
        TokenTransferList[] memory tokenTransfers
    ) external returns (int64 responseCode) {}

    function deleteToken(address token) external returns (int64 responseCode) {}

    function approve(address token, address spender, uint256 amount) external returns (int64 responseCode) {
        // if (!_isFungible[token]) {
        //     responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        // } else if (!_association[token][msg.sender] || !_association[token][spender]) {
        //     responseCode = HederaResponseCodes.TOKEN_NOT_ASSOCIATED_TO_ACCOUNT;
        // } else {
        //     _allowances[token][msg.sender][spender] = amount;
        //     responseCode = HederaResponseCodes.SUCCESS;
        // }
    }

    function approveNFT(address token, address approved, uint256 serialNumber) external returns (int64 responseCode) {
        // if (!_isNonFungible[token]) {
        //     responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        // } else if (!_association[token][msg.sender] || !_association[token][approved]) {
        //     responseCode = HederaResponseCodes.TOKEN_NOT_ASSOCIATED_TO_ACCOUNT;
        // } else {
        //     _allowances[token][msg.sender][approved][serialNumber] = true;
        //     responseCode = HederaResponseCodes.SUCCESS;
        // }
    }

    function associateToken(address account, address token) public returns (int64 responseCode) {
        if (!_isFungible[token] && !_isNonFungible[token]) {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        } else if (_association[account][token]) {
            responseCode = HederaResponseCodes.TOKEN_ALREADY_ASSOCIATED_TO_ACCOUNT;
        } else {
            responseCode = HederaResponseCodes.SUCCESS;
            _association[account][token] = true;
        }
    }

    function associateTokens(address account, address[] memory tokens) external returns (int64 responseCode) {
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

    function dissociateTokens(address account, address[] memory tokens) external returns (int64 responseCode) {
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

    function dissociateToken(address account, address token) public returns (int64 responseCode) {
        if (!_isFungible[token] && !_isNonFungible[token]) {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        } else if (!_association[account][token]) {
            responseCode = HederaResponseCodes.TOKEN_NOT_ASSOCIATED_TO_ACCOUNT;
        } else {
            responseCode = HederaResponseCodes.SUCCESS;
            _association[account][token] = false;
        }
    }

    function freezeToken(address token, address account) external returns (int64 responseCode) {}

    function mintToken(
        address token,
        int64 amount,
        bytes[] memory metadata
    ) external returns (int64 responseCode, int64 newTotalSupply, int64[] memory serialNumbers) {}

    function burnToken(
        address token,
        int64 amount,
        int64[] memory serialNumbers
    ) external returns (int64 responseCode, int64 newTotalSupply) {
        // if (_isFungible[token]) {
        //     FungibleTokenInfo memory fungibleTokenInfo = _fungibleTokenInfo[token];
        //     TokenInfo memory tokenInfo = fungibleTokenInfo.token;
        //     address treasury = tokenInfo.treasury;
        //     if (!_isOriginOrSender(treasury)) {
        //     } else if (not sufficient in treasury) {
        //     } else {
        //         responseCode = HederaResponseCodes.SUCCESS;
        //     }
        // } else if (_isNonFungible[token]) {
        //     NonFungibleTokenInfo memory nonFungibleTokenInfo = _nonFungibleTokenInfo[token];
        // } else {
        //     responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        // }
    }

    function pauseToken(address token) external returns (int64 responseCode) {}

    function revokeTokenKyc(address token, address account) external returns (int64 responseCode) {}

    function setApprovalForAll(address token, address operator, bool approved) external returns (int64 responseCode) {}

    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) external returns (int64 responseCode) {}

    function transferFromNFT(
        address token,
        address from,
        address to,
        uint256 serialNumber
    ) external returns (int64 responseCode) {}

    function transferNFT(
        address token,
        address sender,
        address recipient,
        int64 serialNumber
    ) external returns (int64 responseCode) {}

    function transferNFTs(
        address token,
        address[] memory sender,
        address[] memory receiver,
        int64[] memory serialNumber
    ) external returns (int64 responseCode) {}

    function transferToken(
        address token,
        address sender,
        address recipient,
        int64 amount
    ) external returns (int64 responseCode) {}

    function transferTokens(
        address token,
        address[] memory accountId,
        int64[] memory amount
    ) external returns (int64 responseCode) {}

    function unfreezeToken(address token, address account) external returns (int64 responseCode) {}

    function unpauseToken(address token) external returns (int64 responseCode) {}

    function updateTokenExpiryInfo(address token, Expiry memory expiryInfo) external returns (int64 responseCode) {}

    function updateTokenInfo(address token, HederaToken memory tokenInfo) external returns (int64 responseCode) {}

    function updateTokenKeys(address token, TokenKey[] memory keys) external returns (int64 responseCode) {}

    function wipeTokenAccount(address token, address account, int64 amount) external returns (int64 responseCode) {}

    function wipeTokenAccountNFT(
        address token,
        address account,
        int64[] memory serialNumbers
    ) external returns (int64 responseCode) {}

    function redirectForToken(address token, bytes memory encodedFunctionSelector) external {}

    // Additional(not in IHederaTokenService) public/external state-changing functions:
}
