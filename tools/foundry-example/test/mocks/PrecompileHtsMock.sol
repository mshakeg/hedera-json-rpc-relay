// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'hedera-smart-contracts/hts-precompile/HederaResponseCodes.sol';
import 'hedera-smart-contracts/hts-precompile/IHederaTokenService.sol';

contract PrecompileHtsMock is IHederaTokenService {
    // /// @dev only for Fungible tokens
    // mapping(address => bool) internal _isFungible;
    // // Fungible token -> owner -> spender -> allowance
    // mapping(address => mapping(address => mapping(address => uint256))) internal _allowances;
    // // Fungible token -> FungibleTokenInfo
    // mapping(address => FungibleTokenInfo) _fungibleTokenInfo;
    // // Fungible token -> account -> balance
    // mapping(address => mapping(address => uint256)) _fungibleBalance;

    // /// @dev only for NFT tokens
    // mapping(address => bool) internal _isNFT;
    // // NFT token -> owner -> spender -> serialNumber -> isAllowed
    // mapping(address => mapping(address => mapping(address => mapping(uint256 => bool)))) internal _nftAllowances;
    // // NFT token -> NonFungibleTokenInfo
    // mapping(address => NonFungibleTokenInfo) _nonFungibleTokenInfo;
    // // NFT token -> account -> serialNumber -> exists
    // mapping(address => mapping(address => uint256)) _nftBalance;

    // /// @dev common to both NFT and Fungible HTS tokens
    // // HTS token -> account -> isAssociated
    // mapping(address => mapping(address => bool)) internal _associations;

    function _isOriginOrSender(address account) internal returns (bool) {
        return _isOrigin(account) || _isSender(msg.sender);
    }

    function _isOrigin(address account) internal returns (bool) {
        return account == tx.origin;
    }

    function _isSender(address account) internal returns (bool) {
        return account == msg.sender;
    }

    function allowance(
        address token,
        address owner,
        address spender
    ) external view returns (int64 responseCode, uint256 allowance) {
        // if (!_isFungible[token]) {
        //     responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        // } else {
        //     responseCode = HederaResponseCodes.SUCCESS;
        //     allowance = _allowances[token][owner][spender];
        // }
    }

    function approve(address token, address spender, uint256 amount) external returns (int64 responseCode) {
        // if (!_isFungible[token]) {
        //     responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        // } else if (!_associations[token][msg.sender] || !_associations[token][spender]) {
        //     responseCode = HederaResponseCodes.TOKEN_NOT_ASSOCIATED_TO_ACCOUNT;
        // } else {
        //     _allowances[token][msg.sender][spender] = amount;
        //     responseCode = HederaResponseCodes.SUCCESS;
        // }
    }

    function approveNFT(address token, address approved, uint256 serialNumber) external returns (int64 responseCode) {
        // if (!_isNFT[token]) {
        //     responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        // } else if (!_associations[token][msg.sender] || !_associations[token][approved]) {
        //     responseCode = HederaResponseCodes.TOKEN_NOT_ASSOCIATED_TO_ACCOUNT;
        // } else {
        //     _allowances[token][msg.sender][approved][serialNumber] = true;
        //     responseCode = HederaResponseCodes.SUCCESS;
        // }
    }

    function associateToken(address account, address token) public returns (int64 responseCode) {
        // if (!_isFungible[token] && !_isNFT[token]) {
        //     responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        // } else if (_associations[account][token]) {
        //     responseCode = HederaResponseCodes.TOKEN_ALREADY_ASSOCIATED_TO_ACCOUNT;
        // } else {
        //     responseCode = HederaResponseCodes.SUCCESS;
        //     _associations[account][token] = true;
        // }
    }

    function associateTokens(address account, address[] memory tokens) external returns (int64 responseCode) {
        // responseCode = HederaResponseCodes.SUCCESS;
        // for (uint256 i = 0; i < tokens.length; i++) {
        //     int64 tokenResponseCode = associateToken(account, tokens[i]);
        //     if (tokenResponseCode != HederaResponseCodes.SUCCESS) {
        //         responseCode = tokenResponseCode;
        //         break;
        //     }
        // }
        // return responseCode;
    }

    function burnToken(
        address token,
        uint64 amount,
        int64[] memory serialNumbers
    ) external returns (int64 responseCode, uint64 newTotalSupply) {
        // if (_isFungible[token]) {
        //     FungibleTokenInfo memory fungibleTokenInfo = _fungibleTokenInfo[token];
        //     TokenInfo memory tokenInfo = fungibleTokenInfo.token;
        //     address treasury = tokenInfo.treasury;
        //     if (!_isOriginOrSender(treasury)) {
        //     } else if (not sufficient in treasury) {
        //     } else {
        //         responseCode = HederaResponseCodes.SUCCESS;
        //     }
        // } else if (_isNFT[token]) {
        //     NonFungibleTokenInfo memory nonFungibleTokenInfo = _nonFungibleTokenInfo[token];
        // } else {
        //     responseCode = HederaResponseCodes.INVALID_TOKEN_ID;
        // }
    }

    function createFungibleToken(
        HederaToken memory token,
        uint64 initialTotalSupply,
        uint32 decimals
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
        uint64 initialTotalSupply,
        uint32 decimals,
        FixedFee[] memory fixedFees,
        FractionalFee[] memory fractionalFees
    ) external payable returns (int64 responseCode, address tokenAddress) {}

    function cryptoTransfer(TokenTransferList[] memory tokenTransfers) external returns (int64 responseCode) {}

    function deleteToken(address token) external returns (int64 responseCode) {}

    function dissociateTokens(address account, address[] memory tokens) external returns (int64 responseCode) {}

    function dissociateToken(address account, address token) external returns (int64 responseCode) {}

    function freezeToken(address token, address account) external returns (int64 responseCode) {}

    function getApproved(address token, uint256 serialNumber) external returns (int64 responseCode, address approved) {}

    function getFungibleTokenInfo(
        address token
    ) external returns (int64 responseCode, FungibleTokenInfo memory fungibleTokenInfo) {}

    function getNonFungibleTokenInfo(
        address token,
        int64 serialNumber
    ) external returns (int64 responseCode, NonFungibleTokenInfo memory nonFungibleTokenInfo) {}

    function getTokenCustomFees(
        address token
    )
        external
        returns (
            int64 responseCode,
            FixedFee[] memory fixedFees,
            FractionalFee[] memory fractionalFees,
            RoyaltyFee[] memory royaltyFees
        )
    {}

    function getTokenDefaultFreezeStatus(
        address token
    ) external returns (int64 responseCode, bool defaultFreezeStatus) {}

    function getTokenDefaultKycStatus(address token) external returns (int64 responseCode, bool defaultKycStatus) {}

    function getTokenExpiryInfo(address token) external returns (int64 responseCode, Expiry memory expiry) {}

    function getTokenInfo(address token) external returns (int64 responseCode, TokenInfo memory tokenInfo) {}

    function getTokenKey(address token, uint keyType) external returns (int64 responseCode, KeyValue memory key) {}

    function getTokenType(address token) external returns (int64 responseCode, int32 tokenType) {}

    function grantTokenKyc(address token, address account) external returns (int64 responseCode) {}

    function isApprovedForAll(
        address token,
        address owner,
        address operator
    ) external returns (int64 responseCode, bool approved) {}

    function isFrozen(address token, address account) external returns (int64 responseCode, bool frozen) {}

    function isKyc(address token, address account) external returns (int64 responseCode, bool kycGranted) {}

    function isToken(address token) external returns (int64 responseCode, bool isToken) {}

    function mintToken(
        address token,
        uint64 amount,
        bytes[] memory metadata
    ) external returns (int64 responseCode, uint64 newTotalSupply, int64[] memory serialNumbers) {}

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

    function updateTokenKeys(address token, TokenKey[] memory keys)
        external
        returns (int64 responseCode) {}

    function wipeTokenAccount(
        address token,
        address account,
        uint32 amount
    ) external returns (int64 responseCode) {}

    function wipeTokenAccountNFT(
        address token,
        address account,
        int64[] memory serialNumbers
    ) external returns (int64 responseCode) {}
}
