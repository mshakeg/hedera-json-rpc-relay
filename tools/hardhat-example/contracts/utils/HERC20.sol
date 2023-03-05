// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// util contract to get HTS token info via relay
contract HERC20Util {
    // ERC721 getters
    function name(address token) public view returns (string memory) {
        return IERC20Metadata(token).name();
    }

    function symbol(address token) public view returns (string memory) {
        return IERC20Metadata(token).symbol();
    }

    function decimals(address token) public view returns (uint8) {
        return IERC20Metadata(token).decimals();
    }

    function totalSupply(address token) public view returns (uint256) {
        return IERC20(token).totalSupply();
    }

    function balanceOf(address token, address account) external view returns (uint256) {
        if (token == address(0)) {
            // get native balance
            return account.balance;
        }
        return IERC20(token).balanceOf(account);
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }
}
