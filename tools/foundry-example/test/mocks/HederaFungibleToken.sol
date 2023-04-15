// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

import 'hedera-smart-contracts/hts-precompile/HederaResponseCodes.sol';
import 'hedera-smart-contracts/hts-precompile/IHederaTokenService.sol';
import 'hedera-smart-contracts/hts-precompile/KeyHelper.sol';
import './HtsPrecompileMock.sol';

// TODO: create a tighter coupling between instances of HederaFungibleToken and the HtsPrecompileMock contract
//       such that if a HederaFungibleToken contract is created directly it's registered with the HtsPrecompileMock contract
//       and if an action is attempted directly via the HederaFungibleToken contract it first goes through the HtsPrecompileMock contract
//       and if an action goes through the HtsPrecompileMock contract then it ultimately calls the HederaFungibleToken contract
//       HederaFungibleToken contract should store state related to ERC20 and do validation related to ERC20
//       HtsPrecompileMock contract should store extra state related to the HTS and do validation related to HTS business logic
//       HederaFungibleToken contract should expose special methods only callable by the precompile contract
//       Doing it like this would remove the need for the {grant|revoke}HtsPrecompilePermissions flow

contract HederaFungibleToken is ERC20, KeyHelper {
    address internal constant HTS_PRECOMPILE = address(0x167);
    HtsPrecompileMock internal constant HtsPrecompile = HtsPrecompileMock(HTS_PRECOMPILE);

    bool public constant IS_FUNGIBLE = true; /// @dev if HederaNonFungibleToken then false

    constructor(
        IHederaTokenService.FungibleTokenInfo memory _fungibleTokenInfo
    ) ERC20(_fungibleTokenInfo.tokenInfo.token.name, _fungibleTokenInfo.tokenInfo.token.symbol) {
        HtsPrecompile.registerHederaFungibleToken(_fungibleTokenInfo);
        address treasury = _fungibleTokenInfo.tokenInfo.token.treasury;
        _mint(treasury, uint(uint64(_fungibleTokenInfo.tokenInfo.totalSupply)));
    }

    /// @dev the HtsPrecompileMock should do precheck validation before calling any function with this modifier
    ///      the HtsPrecompileMock has priveleged access to do certain operations
    modifier onlyHtsPrecompile() {
        require(msg.sender == HTS_PRECOMPILE, 'NOT_HTS_PRECOMPILE');
    }

    // public/external state-changing functions:
    // onlyHtsPrecompile functions:
    /// @dev mints "amount" to treasury
    function mintRequestFromHtsPrecompile(int64 amount) external onlyHtsPrecompile {
        (, IHederaTokenService.FungibleTokenInfo memory fungibleTokenInfo) = HtsPrecompile.getFungibleTokenInfo(
            address(this)
        );
        address treasury = fungibleTokenInfo.tokenInfo.token.treasury;
        _mint(treasury, uint64(amount));
    }

    /// @dev burns "amount" from treasury
    function burnRequestFromHtsPrecompile(int64 amount) external onlyHtsPrecompile {
        (, IHederaTokenService.FungibleTokenInfo memory fungibleTokenInfo) = HtsPrecompile.getFungibleTokenInfo(
            address(this)
        );
        address treasury = fungibleTokenInfo.tokenInfo.token.treasury;
        _burn(treasury, uint64(amount));
    }

    /// @dev transfers "amount" from "from" to "to"
    function transferRequestFromHtsPrecompile(address from, address to, uint256 amount) external onlyHtsPrecompile {
        _transfer(from, to, amount);
    }

    /// @dev gives "spender" an allowance of "amount" for "account"
    function approveRequestFromHtsPrecompile(
        address account,
        address spender,
        uint256 amount
    ) external onlyHtsPrecompile {
        _approve(account, spender, amount);
    }

    // standard ERC20 functions overriden for HtsPrecompileMock prechecks:
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }
}
