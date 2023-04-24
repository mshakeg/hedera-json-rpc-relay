// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SimpleVault.sol";

import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

import { HtsPrecompileMock } from './mocks/hts-precompile/HtsPrecompileMock.sol';

contract SimpleVaultTest is Test {

    address alice = vm.addr(1);
    address bob = vm.addr(2);
    address carol = vm.addr(3);
    address dave = vm.addr(4);

    SimpleVault public simpleVault;

    address constant htsPrecompileAddress = address(0x167);

    HtsPrecompileMock htsPrecompile = HtsPrecompileMock(htsPrecompileAddress);

    // setUp is executed before each and every test function
    function setUp() public {
        simpleVault = new SimpleVault();

        HtsPrecompileMock htsPrecompileMock = new HtsPrecompileMock();
        bytes memory code = address(htsPrecompileMock).code;
        vm.etch(htsPrecompileAddress, code);

        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(carol, 100 ether);
        vm.deal(dave, 100 ether);
    }

    function _createToken(address sender) internal returns (address _token) {
        vm.startPrank(sender);
        IHederaTokenService.HederaToken memory token = _getSimpleHederaToken('Token A', 'TA', sender);
        int64 initialTotalSupply = 1e16;
        int32 decimals = 8;
        (int64 responseCode, address tokenAddress) = htsPrecompile.createFungibleToken(
            token,
            initialTotalSupply,
            decimals
        );
        _token = tokenAddress;
        ERC20 erc20Token = ERC20(tokenAddress);
        uint treasuryBalance = erc20Token.balanceOf(sender);
        assertEq(treasuryBalance, uint64(initialTotalSupply), 'expected treasury to have full starting balance');
        bool isAssociated = htsPrecompile.isAssociated(sender, tokenAddress);
        assertEq(isAssociated, true, 'expected treasury to be associated with account');
        vm.stopPrank();
    }

    function _associateToken(address sender, address token) internal {
        vm.startPrank(sender);
        int64 responseCode = htsPrecompile.associateToken(sender, token);
        assertEq(responseCode, HederaResponseCodes.SUCCESS, 'expected sender to be associated with token');
        bool isAssociated = htsPrecompile.isAssociated(sender, token);
        assertEq(isAssociated, true, 'expected sender to be associated with account');
        vm.stopPrank();
    }

    function _transferToken(address token, address sender, address recipient, uint amount) internal {
        vm.startPrank(sender);
        ERC20 erc20Token = ERC20(token);
        erc20Token.transfer(recipient, amount);
        vm.stopPrank();
    }

    function _depositToSimpleVault(address sender, address token, uint64 amount) internal {

        vm.startPrank(sender, sender);

        uint amountU256 = uint(amount);

        ERC20 erc20Token = ERC20(token);

        uint senderStartingTokenBalance = erc20Token.balanceOf(sender);
        uint senderStartingVaultBalance = simpleVault.vaultBalances(token, sender);

        simpleVault.deposit(token, amount);

        uint senderFinalTokenBalance = erc20Token.balanceOf(sender);
        uint senderFinalVaultBalance = simpleVault.vaultBalances(token, sender);

        assertEq(senderStartingTokenBalance - amountU256, senderFinalTokenBalance, "expected spender token balance to decrease after deposit");
        assertEq(senderStartingVaultBalance + amountU256, senderFinalVaultBalance, "expected spender vault balance to increase after deposit");

        vm.stopPrank();

    }

    function _withdrawFromSimpleVault(address sender, address token, uint64 amount) internal {

        vm.startPrank(sender, sender);

        uint amountU256 = uint(amount);

        ERC20 erc20Token = ERC20(token);

        uint senderStartingTokenBalance = erc20Token.balanceOf(sender);
        uint senderStartingVaultBalance = simpleVault.vaultBalances(token, sender);

        simpleVault.withdraw(token, amount);

        uint senderFinalTokenBalance = erc20Token.balanceOf(sender);
        uint senderFinalVaultBalance = simpleVault.vaultBalances(token, sender);

        assertEq(senderStartingTokenBalance + amountU256, senderFinalTokenBalance, "expected spender token balance to increase after withdraw");
        assertEq(senderStartingVaultBalance - amountU256, senderFinalVaultBalance, "expected spender vault balance to decrease after withdraw");

        vm.stopPrank();

    }

    struct DepositAndWithdrawParams {
        address sender;
        address depositToken;
        uint64 depositAmount;
        address withdrawToken;
        uint64 withdrawAmount;
    }

    function _depositAndWithdraw(DepositAndWithdrawParams memory depositAndWithdrawParams) internal {

        vm.startPrank(depositAndWithdrawParams.sender, depositAndWithdrawParams.sender);

        uint depositAmountU256 = uint(depositAndWithdrawParams.depositAmount);
        uint withdrawAmountU256 = uint(depositAndWithdrawParams.withdrawAmount);

        ERC20 erc20DepositToken = ERC20(depositAndWithdrawParams.depositToken);
        ERC20 erc20WithdrawToken = ERC20(depositAndWithdrawParams.withdrawToken);

        uint senderStartingDepositTokenBalance = erc20DepositToken.balanceOf(depositAndWithdrawParams.sender);
        uint senderStartingDepositVaultBalance = simpleVault.vaultBalances(depositAndWithdrawParams.depositToken, depositAndWithdrawParams.sender);

        uint senderStartingWithdrawTokenBalance = erc20WithdrawToken.balanceOf(depositAndWithdrawParams.sender);
        uint senderStartingWithdrawVaultBalance = simpleVault.vaultBalances(depositAndWithdrawParams.withdrawToken, depositAndWithdrawParams.sender);

        simpleVault.depositAndWithdraw(depositAndWithdrawParams.depositToken, depositAndWithdrawParams.depositAmount, depositAndWithdrawParams.withdrawToken, depositAndWithdrawParams.withdrawAmount);

        uint senderFinalDepositTokenBalance = erc20DepositToken.balanceOf(depositAndWithdrawParams.sender);
        uint senderFinalDepositVaultBalance = simpleVault.vaultBalances(depositAndWithdrawParams.depositToken, depositAndWithdrawParams.sender);

        uint senderFinalWithdrawTokenBalance = erc20WithdrawToken.balanceOf(depositAndWithdrawParams.sender);
        uint senderFinalWithdrawVaultBalance = simpleVault.vaultBalances(depositAndWithdrawParams.withdrawToken, depositAndWithdrawParams.sender);

        assertEq(senderStartingDepositTokenBalance - depositAmountU256, senderFinalDepositTokenBalance, "expected spender token balance to decrease after deposit");
        assertEq(senderStartingDepositVaultBalance + depositAmountU256, senderFinalDepositVaultBalance, "expected spender vault balance to increase after deposit");

        assertEq(senderStartingWithdrawTokenBalance + withdrawAmountU256, senderFinalWithdrawTokenBalance, "expected spender token balance to increase after withdraw");
        assertEq(senderStartingWithdrawVaultBalance - withdrawAmountU256, senderFinalWithdrawVaultBalance, "expected spender vault balance to decrease after withdraw");

        vm.stopPrank();

    }

    function _getSimpleHederaToken(
        string memory name,
        string memory symbol,
        address treasury
    ) internal returns (IHederaTokenService.HederaToken memory token) {
        token.name = name;
        token.symbol = symbol;
        token.treasury = treasury;
    }

    function _getSimpleHederaFungibleTokenInfo(
        string memory name,
        string memory symbol,
        address treasury,
        int64 initialTotalSupply,
        int32 decimals
    ) internal returns (IHederaTokenService.FungibleTokenInfo memory fungibleTokenInfo) {
        IHederaTokenService.TokenInfo memory tokenInfo;

        IHederaTokenService.HederaToken memory token = _getSimpleHederaToken(name, symbol, treasury);

        tokenInfo.token = token;
        tokenInfo.totalSupply = initialTotalSupply;

        fungibleTokenInfo.decimals = decimals;
        fungibleTokenInfo.tokenInfo = tokenInfo;
    }

    // positive cases:
    function test_Deposit() public {

        address token = _createToken(alice);
        _associateToken(bob, token);

        uint amount = 1e6;
        _transferToken(token, alice, bob, amount);

        _associateToken(address(simpleVault), token);

        amount = 1e4;
        _depositToSimpleVault(bob, token, uint64(amount));

    }

    function test_Withdraw() public {
        address token = _createToken(alice);

        _associateToken(bob, token);

        uint amount = 1e6;
        _transferToken(token, alice, bob, amount);

        _associateToken(address(simpleVault), token);

        _depositToSimpleVault(bob, token, uint64(amount)); // first deposit before withdraw

        uint withdrawAmount = 1e4;

        _withdrawFromSimpleVault(bob, token, uint64(withdrawAmount));
    }

    function test_DepositAndWithdraw() public {
        address depositToken = _createToken(alice);
        address withdrawToken = _createToken(alice);

        _associateToken(bob, depositToken);
        _associateToken(bob, withdrawToken);

        uint amount = 1e6;
        _transferToken(depositToken, alice, bob, amount);
        _transferToken(withdrawToken, alice, bob, amount);

        _associateToken(address(simpleVault), depositToken);
        _associateToken(address(simpleVault), withdrawToken);

        _depositToSimpleVault(bob, withdrawToken, uint64(amount)); // first deposit before withdraw

        uint depositAmount = 1e4;
        uint withdrawAmount = 1e4;
        DepositAndWithdrawParams memory depositAndWithdrawParams = DepositAndWithdrawParams({
            sender: bob,
            depositToken: depositToken,
            depositAmount: uint64(depositAmount),
            withdrawToken: withdrawToken,
            withdrawAmount: uint64(withdrawAmount)
        });
    }

    // negative cases:
    function test_CannotDepositIfNotAssociated() public {
    }

    function test_CannotWithdrawIfNotAssociated() public {
    }
}

// forge test --match-contract SimpleVaultTest --match-test test_Withdraw -vv