// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import "../_precompile-hts/HederaTokenService.sol";
import "../_precompile-hts/HederaResponseCodes.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Associator is HederaTokenService {
    error AssociateTokenError(int256 errorCode, address account, address token);

    function associateSender(address token) external returns (int256 response) {
        response = HederaTokenService.associateToken(msg.sender, token);
        if (response != HederaResponseCodes.SUCCESS && response != HederaResponseCodes.TOKEN_ALREADY_ASSOCIATED_TO_ACCOUNT) {
            revert AssociateTokenError(response, address(this), token);
        }
    }

    function balanceOf(address token, address account) external view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }

    function getBalance(address account) external view returns (uint256) {
        return account.balance;
    }
}
