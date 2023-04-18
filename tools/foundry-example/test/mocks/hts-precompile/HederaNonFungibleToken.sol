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

    // serialNumber -> spender -> approved
    mapping(int64 => mapping(address => bool)) internal _tokenApprovals; /// @dev _tokenApprovals in ERC721 is private

    bool public constant IS_FUNGIBLE = false; /// @dev if HederaFungibleToken then true

    struct NFTCounter {
        int64 minted;
        int64 burned;
    }

    NFTCounter public nftCount;

    /// @dev NonFungibleTokenInfo is for each NFT(with a unique serial number) that is minted; however TokenInfo covers the common token info across all instances
    constructor(
        IHederaTokenService.TokenInfo memory _nftTokenInfo
    ) ERC721(_nftTokenInfo.token.name, _nftTokenInfo.token.symbol) {
        HtsPrecompile.registerHederaNonFungibleToken(_nftTokenInfo);
    }

    /// @dev the HtsPrecompileMock should do precheck validation before calling any function with this modifier
    ///      the HtsPrecompileMock has priveleged access to do certain operations
    modifier onlyHtsPrecompile() {
        require(msg.sender == HTS_PRECOMPILE, 'NOT_HTS_PRECOMPILE');
        _;
    }

    // public/external state-changing functions:
    // onlyHtsPrecompile functions:
    function mintRequestFromHtsPrecompile(bytes[] memory metadata) external onlyHtsPrecompile returns(int64 newTotalSupply, int64 serialNumber) {
        (, IHederaTokenService.FungibleTokenInfo memory fungibleTokenInfo) = HtsPrecompile.getFungibleTokenInfo(
            address(this)
        );
        address treasury = fungibleTokenInfo.tokenInfo.token.treasury;
        serialNumber = ++nftCount.minted;
        _mint(treasury, uint64(serialNumber));

        newTotalSupply = int64(int256(totalSupply()));
    }

    function burnRequestFromHtsPrecompile(int64[] calldata tokenIds) external onlyHtsPrecompile returns(int64 newTotalSupply) {
        int64 burnCount = int64(uint64(tokenIds.length));
        nftCount.burned = nftCount.burned + burnCount;

        for (uint256 i = 0; i < uint64(burnCount); i++) {
            uint256 tokenId = uint64(tokenIds[i]);
            _burn(tokenId);
        }

        newTotalSupply = int64(int256(totalSupply()));
    }

    /// @dev transfers "amount" from "from" to "to"
    function transferRequestFromHtsPrecompile(bool isRequestFromOwner, address spender, address from, address to, int64 tokenId) external onlyHtsPrecompile returns (int64 responseCode) {
        bool isSpenderApproved = _isApprovedOrOwner(spender, uint64(tokenId));
        if (!isSpenderApproved) {
            responseCode = HederaResponseCodes.INSUFFICIENT_TOKEN_BALANCE;
        } else {
            if (_tokenApprovals[tokenId][spender]) {
                _tokenApprovals[tokenId][spender] = false;
                _transfer(from, to, uint64(tokenId));
                responseCode = HederaResponseCodes.SUCCESS;
            } else {
                responseCode = HederaResponseCodes.INSUFFICIENT_TOKEN_BALANCE;
            }
        }
    }

    function approveRequestFromHtsPrecompile(
        address spender,
        int64 tokenId
    ) external onlyHtsPrecompile {
        _tokenApprovals[tokenId][spender] = true;
        _approve(spender, uint64(tokenId));
    }

    function setApprovalForAllFromHtsPrecompile(
        address owner,
        address operator,
        bool approved
    ) external onlyHtsPrecompile {
        _setApprovalForAll(owner, operator, approved);
    }

    // Additional(not in IHederaTokenService or in IERC721) public/external view functions:
    function totalSupply() public view returns (uint256) {
        return uint64(nftCount.minted - nftCount.burned);
    }
}
