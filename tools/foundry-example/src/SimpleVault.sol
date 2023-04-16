// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "hedera-smart-contracts/safe-hts-precompile/SafeHTS.sol";

contract SimpleVault {

    mapping(address => bool) public isAssociated;
    mapping(address => mapping(address => uint64)) public vaultBalances;

    function associate(address token) external {
        if (!isAssociated[token]) {
            SafeHTS.safeAssociateToken(token, address(this));
            isAssociated[token] = true;
        }
    }

    function depositAndWithdraw(address depositToken, uint64 depositAmount, address withdrawToken, uint64 withdrawAmount) public {
        deposit(depositToken, depositAmount);
        withdraw(withdrawToken, withdrawAmount);
    }

    function deposit(address token, uint64 amount) public {
        SafeHTS.safeTransferToken(token, msg.sender, address(this), int64(amount));
        vaultBalances[token][msg.sender] += amount;
    }

    function withdraw(address token, uint64 amount) public {
        SafeHTS.safeTransferToken(token, address(this), msg.sender, int64(amount));
        vaultBalances[token][msg.sender] -= amount;
    }
}