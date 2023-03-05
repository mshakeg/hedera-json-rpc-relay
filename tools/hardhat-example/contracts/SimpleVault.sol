// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./_precompile-safe-hts/SafeHTS.sol";
import "./_precompile-hts/HederaTokenService.sol";
import "./_precompile-hts/HederaResponseCodes.sol";

contract SimpleVault {

    mapping(address => bool) public isAssociated;

    function associate(address token) external {
        if (!isAssociated[token]) {
            SafeHTS.safeAssociateToken(token, address(this));
            isAssociated[token] = true;
        }
    }

    function deposit(address token, uint64 amount) external payable {
        SafeHTS.safeTransferToken(token, msg.sender, address(this), int64(amount));
    }

    function withdraw(address token, uint64 amount) external {
        SafeHTS.safeTransferToken(token, address(this), msg.sender, int64(amount));
    }
}
