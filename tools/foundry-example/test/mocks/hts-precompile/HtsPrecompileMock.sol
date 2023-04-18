// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/console.sol';

import 'hedera-smart-contracts/hts-precompile/HederaResponseCodes.sol';
import 'hedera-smart-contracts/hts-precompile/IHederaTokenService.sol';
import 'hedera-smart-contracts/hts-precompile/KeyHelper.sol';
import './HederaFungibleToken.sol';
import '../../../src/NoDelegateCall.sol';

contract HtsPrecompileMock is NoDelegateCall, IHederaTokenService, KeyHelper {
    address internal constant HTS_PRECOMPILE = address(0x167);

    /// @dev only for Fungible tokens
    // Fungible token -> FungibleTokenInfo
    mapping(address => FungibleTokenInfo) internal _fungibleTokenInfos;
    // Fungible token -> _isFungible
    mapping(address => bool) internal _isFungible;

    /// @dev only for NonFungibleToken
    // // NFT token -> TokenInfo; TokenInfo is used instead of NonFungibleTokenInfo as the former is common to all NFT instances whereas the latter is for a specific NFT instance(uniquely identified by its serialNumber)
    mapping(address => TokenInfo) internal _nftTokenInfos;
    // // NFT token -> serialNumber -> PartialNonFungibleTokenInfo
    mapping(address => mapping(int64 => PartialNonFungibleTokenInfo)) internal _partialNonFungibleTokenInfos;
    // NFT token -> _isNonFungible
    mapping(address => bool) internal _isNonFungible;

    /// @dev common to both NFT and Fungible HTS tokens
    // HTS token -> account -> isAssociated
    mapping(address => mapping(address => bool)) internal _association;
    // HTS token -> account -> isKyced
    mapping(address => mapping(address => bool)) internal _kyc;
    // HTS token -> account -> isFrozen
    mapping(address => mapping(address => bool)) internal _frozen;
    // HTS token -> keyType -> value e.g. 1 -> 0x123 means that the ADMIN is account 0x123
    mapping(address => mapping(uint => address)) internal _tokenKeys; /// @dev faster access then getting keys via {FungibleTokenInfo|NonFungibleTokenInfo}#TokenInfo.HederaToken.tokenKeys[]; however only supports KeyValueType.CONTRACT_ID

    // this struct avoids duplicating common NFT data, in particular IHederaTokenService.NonFungibleTokenInfo.tokenInfo
    struct PartialNonFungibleTokenInfo {
        address ownerId;
        int64 creationTime;
        bytes metadata;
        address spenderId;
    }

    constructor() NoDelegateCall(HTS_PRECOMPILE) {}

    modifier onlyHederaToken() {
        require(_isToken(msg.sender), 'NOT_HEDERA_TOKEN');
        _;
    }

    function _isToken(address token) internal view returns (bool) {
        return _isFungible[token] || _isNonFungible[token];
    }

    function _isAccountOriginOrSender(address account) internal view returns (bool) {
        return _isAccountOrigin(account) || _isAccountSender(account);
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

    function _setFungibleTokenInfo(FungibleTokenInfo memory fungibleTokenInfo) internal returns (address treasury) {
        address tokenAddress = msg.sender;
        _fungibleTokenInfos[tokenAddress].tokenInfo.token.name = fungibleTokenInfo.tokenInfo.token.name;
        _fungibleTokenInfos[tokenAddress].tokenInfo.token.symbol = fungibleTokenInfo.tokenInfo.token.symbol;
        _fungibleTokenInfos[tokenAddress].tokenInfo.token.treasury = fungibleTokenInfo.tokenInfo.token.treasury;

        treasury = fungibleTokenInfo.tokenInfo.token.treasury;

        _fungibleTokenInfos[tokenAddress].tokenInfo.token.memo = fungibleTokenInfo.tokenInfo.token.memo;
        _fungibleTokenInfos[tokenAddress].tokenInfo.token.tokenSupplyType = fungibleTokenInfo
            .tokenInfo
            .token
            .tokenSupplyType;
        _fungibleTokenInfos[tokenAddress].tokenInfo.token.maxSupply = fungibleTokenInfo.tokenInfo.token.maxSupply;
        _fungibleTokenInfos[tokenAddress].tokenInfo.token.freezeDefault = fungibleTokenInfo.tokenInfo.token.freezeDefault;

        // Copy the tokenKeys array
        uint256 length = fungibleTokenInfo.tokenInfo.token.tokenKeys.length;
        for (uint256 i = 0; i < length; i++) {
            TokenKey memory tokenKey = fungibleTokenInfo.tokenInfo.token.tokenKeys[i];
            _fungibleTokenInfos[tokenAddress].tokenInfo.token.tokenKeys.push(tokenKey);

            /// @dev contractId can in fact be any address including an EOA address
            ///      The KeyHelper lists 5 types for KeyValueType; however only CONTRACT_ID is considered
            _tokenKeys[tokenAddress][tokenKey.keyType] = tokenKey.key.contractId;
        }

        _fungibleTokenInfos[tokenAddress].tokenInfo.token.expiry.second = fungibleTokenInfo.tokenInfo.token.expiry.second;
        _fungibleTokenInfos[tokenAddress].tokenInfo.token.expiry.autoRenewAccount = fungibleTokenInfo
            .tokenInfo
            .token
            .expiry
            .autoRenewAccount;
        _fungibleTokenInfos[tokenAddress].tokenInfo.token.expiry.autoRenewPeriod = fungibleTokenInfo
            .tokenInfo
            .token
            .expiry
            .autoRenewPeriod;

        _fungibleTokenInfos[tokenAddress].tokenInfo.totalSupply = fungibleTokenInfo.tokenInfo.totalSupply;
        _fungibleTokenInfos[tokenAddress].tokenInfo.deleted = fungibleTokenInfo.tokenInfo.deleted;
        _fungibleTokenInfos[tokenAddress].tokenInfo.defaultKycStatus = fungibleTokenInfo.tokenInfo.defaultKycStatus;
        _fungibleTokenInfos[tokenAddress].tokenInfo.pauseStatus = fungibleTokenInfo.tokenInfo.pauseStatus;

        // Handle copying of other arrays (fixedFees, fractionalFees, and royaltyFees) if needed

        _fungibleTokenInfos[tokenAddress].tokenInfo.ledgerId = fungibleTokenInfo.tokenInfo.ledgerId;
        _fungibleTokenInfos[tokenAddress].decimals = fungibleTokenInfo.decimals;
    }

    function _setNftTokenInfo(TokenInfo memory nftTokenInfo) internal returns (address treasury) {
        address tokenAddress = msg.sender;
        _nftTokenInfos[tokenAddress].token.name = nftTokenInfo.token.name;
        _nftTokenInfos[tokenAddress].token.symbol = nftTokenInfo.token.symbol;
        _nftTokenInfos[tokenAddress].token.treasury = nftTokenInfo.token.treasury;

        treasury = nftTokenInfo.token.treasury;

        _nftTokenInfos[tokenAddress].token.memo = nftTokenInfo.token.memo;
        _nftTokenInfos[tokenAddress].token.tokenSupplyType = nftTokenInfo
            .token
            .tokenSupplyType;
        _nftTokenInfos[tokenAddress].token.maxSupply = nftTokenInfo.token.maxSupply;
        _nftTokenInfos[tokenAddress].token.freezeDefault = nftTokenInfo.token.freezeDefault;

        // Copy the tokenKeys array
        uint256 length = nftTokenInfo.token.tokenKeys.length;
        for (uint256 i = 0; i < length; i++) {
            TokenKey memory tokenKey = nftTokenInfo.token.tokenKeys[i];
            _nftTokenInfos[tokenAddress].token.tokenKeys.push(tokenKey);

            /// @dev contractId can in fact be any address including an EOA address
            ///      The KeyHelper lists 5 types for KeyValueType; however only CONTRACT_ID is considered
            _tokenKeys[tokenAddress][tokenKey.keyType] = tokenKey.key.contractId;
        }

        _nftTokenInfos[tokenAddress].token.expiry.second = nftTokenInfo.token.expiry.second;
        _nftTokenInfos[tokenAddress].token.expiry.autoRenewAccount = nftTokenInfo
            .token
            .expiry
            .autoRenewAccount;
        _nftTokenInfos[tokenAddress].token.expiry.autoRenewPeriod = nftTokenInfo
            .token
            .expiry
            .autoRenewPeriod;

        _nftTokenInfos[tokenAddress].totalSupply = nftTokenInfo.totalSupply;
        _nftTokenInfos[tokenAddress].deleted = nftTokenInfo.deleted;
        _nftTokenInfos[tokenAddress].defaultKycStatus = nftTokenInfo.defaultKycStatus;
        _nftTokenInfos[tokenAddress].pauseStatus = nftTokenInfo.pauseStatus;

        // Handle copying of other arrays (fixedFees, fractionalFees, and royaltyFees) if needed

        _nftTokenInfos[tokenAddress].ledgerId = nftTokenInfo.ledgerId;
    }

    function _preCreateToken(HederaToken memory token) internal view returns (int64 responseCode) {
        bool validTreasurySig = _isAccountOriginOrSender(token.treasury);
        // TODO: add additional validation on token; validation most likely required on only tokenKeys(if an address(contract/EOA) has a zero-balance then consider the tokenKey invalid since active accounts on Hedera must have a positive HBAR balance)

        if (validTreasurySig) {
            responseCode = HederaResponseCodes.SUCCESS;
        } else {
            responseCode = HederaResponseCodes.AUTHORIZATION_FAILED;
        }
    }

    /// @dev the following internal _precheck functions are called in either of the following 2 scenarios:
    ///      1. before the HtsPrecompileMock calls any of the HederaFungibleToken or HederaNonFungibleToken functions that specify the onlyHtsPrecompile modifier
    ///      2. in any of HtsPrecompileMock functions that specifies the onlyHederaToken modifier which is only callable by a HederaFungibleToken or HederaNonFungibleToken contract

    /// @dev for both Fungible and NonFungible
    function _precheckApprove(
        address token,
        address owner,
        address spender,
        uint256 amountOrSerialNumber /// for Fungible is the amount and for NonFungible is the serialNumber
    ) internal view returns (int64 responseCode) {
        if (!_isFungible[token]) {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        } else if (!_association[token][owner] || !_association[token][spender]) {
            responseCode = HederaResponseCodes.TOKEN_NOT_ASSOCIATED_TO_ACCOUNT;
        } else {
            responseCode = HederaResponseCodes.SUCCESS;
        }
    }

    function _precheckSetApprovalForAll(
        address token,
        address owner,
        address operator,
        bool approved
    ) internal view returns (int64 responseCode) {

    }

    function _precheckMint(
        address token,
        int64 amount,
        bytes[] memory metadata
    ) internal view returns (int64 responseCode) {
        bool isFungible = _isFungible[token];
        bool isNonFungible = _isNonFungible[token];
        if (isFungible) {
            (bool validKey, bool noKey) = _hasSupplyKeySig(token);

            if (noKey) {
                responseCode = HederaResponseCodes.TOKEN_HAS_NO_SUPPLY_KEY;
            } else if (!validKey) {
                responseCode = HederaResponseCodes.INVALID_SUPPLY_KEY;
            } else {
                responseCode = HederaResponseCodes.SUCCESS;
            }
        } else if (isNonFungible) {
            // TODO: NonFungibleToken
        } else {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        }
    }

    function _precheckBurn(
        address token,
        int64 amount,
        int64[] memory serialNumbers
    ) internal view returns (int64 responseCode) {
        bool isFungible = _isFungible[token];
        bool isNonFungible = _isNonFungible[token];

        if (_isFungible[token]) {
            (bool validKey, bool noKey) = _hasTreasurySig(token);

            if (noKey || !validKey) {
                /// @dev noKey should always be false as a token must have a treasury account; however use INVALID_TREASURY_ACCOUNT_FOR_TOKEN if treasury has been deleted
                responseCode = HederaResponseCodes.AUTHORIZATION_FAILED;
            } else {
                responseCode = HederaResponseCodes.SUCCESS;
            }
        } else if (_isNonFungible[token]) {
            // TODO: NonFungibleToken
            TokenInfo memory nftTokenInfo = _nftTokenInfos[token];
        } else {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        }
    }

    function _precheckTransfer(
        address token,
        address spender,
        address from,
        address to,
        uint256 amount
    ) internal view returns (int64 responseCode, bool isRequestFromOwner) {
        bool isFungible = _isFungible[token];

        // extract logic for preTransfer
        // if returns HederaResponseCodes.SUCCESS then call transferRequestFromHtsPrecompile

        (, bool doesFromPassKyc) = isKyc(token, from);
        (, bool doesToPassKyc) = isKyc(token, to);

        if (!_association[token][from] || !_association[token][to]) {
            responseCode = HederaResponseCodes.TOKEN_NOT_ASSOCIATED_TO_ACCOUNT;
        } else if (_frozen[token][from] || _frozen[token][to]) {
            responseCode = HederaResponseCodes.ACCOUNT_FROZEN_FOR_TOKEN;
        } else if (!doesFromPassKyc || !doesToPassKyc) {
            responseCode = HederaResponseCodes.ACCOUNT_KYC_NOT_GRANTED_FOR_TOKEN;
        } else {
            if (_isFungible[token]) {
                /// @dev should have sign from "from" or sender should have sufficient allowance for from

                /// @dev if transfer request is not from owner then check allowance of msg.sender
                bool shouldAssumeRequestFromOwner = spender == ADDRESS_ZERO;
                isRequestFromOwner = _isAccountOriginOrSender(from) || shouldAssumeRequestFromOwner;

                if (isRequestFromOwner) {
                    responseCode = HederaResponseCodes.SUCCESS;
                } else {
                    address spender = spender; /// TODO: investigate if Hedera also considers tx.origin as a possible spender
                    (, uint256 spenderAllowance) = allowance(token, from, spender);
                    if (spenderAllowance < amount) {
                        responseCode = HederaResponseCodes.INSUFFICIENT_ACCOUNT_BALANCE; /// TODO: investigate if this response code is suitable for insufficient allowance
                    } else {
                        responseCode = HederaResponseCodes.SUCCESS;
                    }
                }
            } else {
                responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
            }
        }
    }

    function preApprove(
        address owner,
        address spender,
        uint256 amount
    ) external onlyHederaToken returns (int64 responseCode) {
        address token = msg.sender;
        responseCode = _precheckApprove(token, owner, spender, amount);
    }

    function preSetApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal view returns (int64 responseCode) {
        address token = msg.sender;
        responseCode = _precheckSetApprovalForAll(token, owner, operator, approved);
    }

    /// @dev not currently called by Hedera{}Token
    function preMint(
        address token,
        int64 amount,
        bytes[] memory metadata
    ) external onlyHederaToken returns (int64 responseCode) {
        address token = msg.sender;
        responseCode = _precheckMint(token, amount, metadata);
    }

    /// @dev not currently called by Hedera{}Token
    function preBurn(int64 amount, int64[] memory serialNumbers) external onlyHederaToken returns (int64 responseCode) {
        address token = msg.sender;
        responseCode = _precheckBurn(token, amount, serialNumbers);
    }

    function preTransfer(
        address spender, /// @dev if spender == ADDRESS_ZERO then assume ERC20#transfer(i.e. msg.sender is attempting to spend their balance) otherwise ERC20#transferFrom(i.e. msg.sender is attempting to spend balance of "from" using allowance)
        address from,
        address to,
        uint256 amount
    ) external onlyHederaToken returns (int64 responseCode) {
        address token = msg.sender;
        (responseCode, ) = _precheckTransfer(token, spender, from, to, amount);
    }

    /// @dev register HederaFungibleToken; msg.sender is the HederaFungibleToken
    ///      can be called by any contract; however assumes msg.sender is a HederaFungibleToken
    function registerHederaFungibleToken(FungibleTokenInfo memory fungibleTokenInfo) external {
        address tokenAddress = msg.sender;
        _isFungible[tokenAddress] = true;
        address treasury = _setFungibleTokenInfo(fungibleTokenInfo);
        associateToken(treasury, tokenAddress);
    }

    /// @dev register HederaNonFungibleToken; msg.sender is the HederaNonFungibleToken
    ///      can be called by any contract; however assumes msg.sender is a HederaNonFungibleToken
    function registerHederaNonFungibleToken(TokenInfo memory nftTokenInfo) external {
        address tokenAddress = msg.sender;
        _isNonFungible[tokenAddress] = true;
        address treasury = _setNftTokenInfo(nftTokenInfo);
        associateToken(treasury, tokenAddress);
    }

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
        TokenInfo memory nftTokenInfo = _nftTokenInfos[token];
        PartialNonFungibleTokenInfo memory partialNonFungibleTokenInfo = _partialNonFungibleTokenInfos[token][serialNumber];

        nonFungibleTokenInfo.tokenInfo = nftTokenInfo;

        nonFungibleTokenInfo.serialNumber = serialNumber;

        nonFungibleTokenInfo.ownerId = partialNonFungibleTokenInfo.ownerId;
        nonFungibleTokenInfo.creationTime = partialNonFungibleTokenInfo.creationTime;
        nonFungibleTokenInfo.metadata = partialNonFungibleTokenInfo.metadata;
        nonFungibleTokenInfo.spenderId = partialNonFungibleTokenInfo.spenderId;

        responseCode = HederaResponseCodes.SUCCESS;
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

    function getTokenDefaultKycStatus(address token) external view returns (int64 responseCode, bool defaultKycStatus) {
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
            responseCode = HederaResponseCodes.SUCCESS;
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
            // TODO: consider token's freezeDefault
            frozen = _frozen[token][account];
            responseCode = HederaResponseCodes.SUCCESS;
        }
    }

    function isKyc(address token, address account) public view returns (int64 responseCode, bool kycGranted) {
        kycGranted = true; /// @dev by default KYC is granted and only if the token has a KYC key then consider _kyc
        if (!_isFungible[token] && !_isNonFungible[token]) {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        } else if (getKey(token, KeyHelper.KeyType.KYC) == ADDRESS_ZERO) {
            responseCode = HederaResponseCodes.TOKEN_HAS_NO_KYC_KEY;
        } else {
            // TODO: consider token's defaultKycStatus
            kycGranted = _kyc[token][account];
            responseCode = HederaResponseCodes.SUCCESS;
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
    ) public view returns (int64 responseCode, uint256 allowance) {
        if (!_isFungible[token]) {
            responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        } else {
            responseCode = HederaResponseCodes.SUCCESS;
            allowance = HederaFungibleToken(token).allowance(owner, spender);
        }
    }

    // Additional(not in IHederaTokenService) public/external view functions:
    function getKey(address token, KeyHelper.KeyType keyType) public view returns (address keyOwner) {
        /// @dev for some reason getKeyType does not return the correct uint value; e.g. keyType = SUPPLY(i.e. 4) should return 16, but instead returns the enum value i.e. 4
        ///      hence 2 ** keyType is used instead
        uint _keyType = 2 ** uint(keyType);
        // uint _keyType = getKeyType(keyType);
        keyOwner = _tokenKeys[token][_keyType];
    }

    // IHederaTokenService public/external state-changing functions:
    function createFungibleToken(
        HederaToken memory token,
        int64 initialTotalSupply,
        int32 decimals
    ) external payable noDelegateCall returns (int64 responseCode, address tokenAddress) {
        responseCode = _preCreateToken(token);
        if (responseCode == HederaResponseCodes.SUCCESS) {
            if (decimals < 0 || decimals > 18) {
                responseCode = HederaResponseCodes.INVALID_TOKEN_DECIMALS;
            } else if (initialTotalSupply < 0) {
                responseCode = HederaResponseCodes.INVALID_TOKEN_INITIAL_SUPPLY;
            } else {
                FungibleTokenInfo memory fungibleTokenInfo;
                TokenInfo memory tokenInfo;

                tokenInfo.token = token;
                tokenInfo.totalSupply = initialTotalSupply;

                fungibleTokenInfo.decimals = decimals;
                fungibleTokenInfo.tokenInfo = tokenInfo;

                /// @dev no need to register newly created HederaFungibleToken in this context as the constructor will call HtsPrecompileMock#registerHederaFungibleToken
                HederaFungibleToken hederaFungibleToken = new HederaFungibleToken(fungibleTokenInfo);
                responseCode = HederaResponseCodes.SUCCESS;
                tokenAddress = address(hederaFungibleToken);
            }
        }
    }

    function createNonFungibleToken(
        HederaToken memory token
    ) external payable noDelegateCall returns (int64 responseCode, address tokenAddress) {
        // TODO: NonFungibleToken
        // TODO: add internal function to validate HederaToken
    }

    function createFungibleTokenWithCustomFees(
        HederaToken memory token,
        int64 initialTotalSupply,
        int32 decimals,
        FixedFee[] memory fixedFees,
        FractionalFee[] memory fractionalFees
    ) external payable noDelegateCall returns (int64 responseCode, address tokenAddress) {
        // TODO: add internal function to validate HederaToken
        responseCode = _preCreateToken(token);
        if (responseCode == HederaResponseCodes.SUCCESS) {
            if (decimals < 0 || decimals > 18) {
                responseCode = HederaResponseCodes.INVALID_TOKEN_DECIMALS;
            } else if (initialTotalSupply < 0) {
                responseCode = HederaResponseCodes.INVALID_TOKEN_INITIAL_SUPPLY;
            } else {
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
                responseCode = HederaResponseCodes.SUCCESS;
                tokenAddress = address(hederaFungibleToken);
            }
        }
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
        address owner = msg.sender;
        responseCode = _precheckApprove(token, owner, spender, amount);
        if (responseCode == HederaResponseCodes.SUCCESS) {
            HederaFungibleToken(token).approveRequestFromHtsPrecompile(owner, spender, amount);
        }
    }

    // TODO: for NFT
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
        } else if (_association[token][account]) {
            responseCode = HederaResponseCodes.TOKEN_ALREADY_ASSOCIATED_TO_ACCOUNT;
        } else {
            responseCode = HederaResponseCodes.SUCCESS;
            _association[token][account] = true;
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
        } else if (!_association[token][account]) {
            responseCode = HederaResponseCodes.TOKEN_NOT_ASSOCIATED_TO_ACCOUNT;
        } else {
            responseCode = HederaResponseCodes.SUCCESS;
            _association[token][account] = false;
        }
    }

    function freezeToken(address token, address account) external noDelegateCall returns (int64 responseCode) {}

    function mintToken(
        address token,
        int64 amount,
        bytes[] memory metadata
    ) external noDelegateCall returns (int64 responseCode, int64 newTotalSupply, int64[] memory serialNumbers) {
        responseCode = _precheckMint(token, amount, metadata);
        if (responseCode == HederaResponseCodes.SUCCESS) {
            // TODO: both HTS types
            HederaFungibleToken(token).mintRequestFromHtsPrecompile(amount);
        }
    }

    function burnToken(
        address token,
        int64 amount,
        int64[] memory serialNumbers
    ) external noDelegateCall returns (int64 responseCode, int64 newTotalSupply) {
        responseCode = _precheckBurn(token, amount, serialNumbers);
        if (responseCode == HederaResponseCodes.SUCCESS) {
            // TODO: both HTS types
            HederaFungibleToken(token).burnRequestFromHtsPrecompile(amount);
        }
    }

    function pauseToken(address token) external noDelegateCall returns (int64 responseCode) {}

    function revokeTokenKyc(address token, address account) external noDelegateCall returns (int64 responseCode) {}

    // TODO: for NFT
    function setApprovalForAll(
        address token,
        address operator,
        bool approved
    ) external noDelegateCall returns (int64 responseCode) {
        // _precheckSetApprovalForAll
    }

    /// @dev only for HederaFungibleToken
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) external noDelegateCall returns (int64 responseCode) {
        /// @dev spender is set to non-zero address such that shouldAssumeRequestFromOwner always evaluates to false if HtsPrecompileMock#transferFrom is called
        address spender = msg.sender;
        bool isRequestFromOwner;
        (responseCode, isRequestFromOwner) = _precheckTransfer(token, spender, from, to, amount);
        if (responseCode == HederaResponseCodes.SUCCESS) {
            HederaFungibleToken(token).transferRequestFromHtsPrecompile(isRequestFromOwner, spender, from, to, amount);
        }
    }

    // TODO: for NFT
    function transferFromNFT(
        address token,
        address from,
        address to,
        uint256 serialNumber
    ) external noDelegateCall returns (int64 responseCode) {
        // TODO: NonFungibleToken
    }

    // TODO: for NFT
    function transferNFT(
        address token,
        address sender,
        address recipient,
        int64 serialNumber
    ) external noDelegateCall returns (int64 responseCode) {
        // TODO: NonFungibleToken
    }

    // TODO: for NFT
    function transferNFTs(
        address token,
        address[] memory sender,
        address[] memory receiver,
        int64[] memory serialNumber
    ) external noDelegateCall returns (int64 responseCode) {
        // TODO: NonFungibleToken
    }

    // TODO: for fungible
    function transferToken(
        address token,
        address sender,
        address recipient,
        int64 amount
    ) external noDelegateCall returns (int64 responseCode) {}

    // TODO: for fungible
    function transferTokens(
        address token,
        address[] memory accountId,
        int64[] memory amount
    ) external noDelegateCall returns (int64 responseCode) {}

    function unfreezeToken(address token, address account) external noDelegateCall returns (int64 responseCode) {}

    function unpauseToken(address token) external noDelegateCall returns (int64 responseCode) {}

    function updateTokenExpiryInfo(
        address token,
        Expiry memory expiryInfo
    ) external noDelegateCall returns (int64 responseCode) {}

    function updateTokenInfo(
        address token,
        HederaToken memory tokenInfo
    ) external noDelegateCall returns (int64 responseCode) {}

    function updateTokenKeys(
        address token,
        TokenKey[] memory keys
    ) external noDelegateCall returns (int64 responseCode) {}

    function wipeTokenAccount(
        address token,
        address account,
        int64 amount
    ) external noDelegateCall returns (int64 responseCode) {}

    function wipeTokenAccountNFT(
        address token,
        address account,
        int64[] memory serialNumbers
    ) external noDelegateCall returns (int64 responseCode) {
        // TODO: NonFungibleToken
    }

    function redirectForToken(address token, bytes memory encodedFunctionSelector) external noDelegateCall {}

    // Additional(not in IHederaTokenService) public/external state-changing functions:
    function isAssociated(address account, address token) external view returns (bool associated) {
        associated = _association[token][account];
    }
}
