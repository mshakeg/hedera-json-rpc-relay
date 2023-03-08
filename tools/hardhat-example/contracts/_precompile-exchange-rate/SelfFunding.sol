// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.0 <0.9.0;

import "./IExchangeRate.sol";

abstract contract SelfFunding {
    uint256 constant TINY_PARTS_PER_WHOLE = 100_000_000;
    uint256 constant TINY_PARTS_PER_CENTICENT = 1_000_000;
    address constant PRECOMPILE_ADDRESS = address(0x168);

    error InsufficientFee();
    error TransferNativeFailed();

    function tinycentsToTinybars(uint256 tinycents) internal returns (uint256 tinybars) {
        (bool success, bytes memory result) = PRECOMPILE_ADDRESS.call(
            abi.encodeWithSelector(IExchangeRate.tinycentsToTinybars.selector, tinycents)
        );
        require(success);
        tinybars = abi.decode(result, (uint256));
    }

    function tinybarsToTinycents(uint256 tinybars) internal returns (uint256 tinycents) {
        (bool success, bytes memory result) = PRECOMPILE_ADDRESS.call(
            abi.encodeWithSelector(IExchangeRate.tinybarsToTinycents.selector, tinybars)
        );
        require(success);
        tinycents = abi.decode(result, (uint256));
    }

    // converts cents to tinyCents or hbar to tinybars
    function toTiny(uint256 whole) internal pure returns (uint256 tiny) {
        tiny = whole * TINY_PARTS_PER_WHOLE;
    }

    function centiCentsToTinybars(uint256 centiCents) internal returns (uint256 tinybars) {
        uint256 tinycents = centiCents * TINY_PARTS_PER_CENTICENT;
        tinybars = tinycentsToTinybars(tinycents);
    }

    function transferTinybars(uint256 tinybars, address recipient) internal {
        (bool success, ) = payable(recipient).call{value: tinybars}("");

        if (!success) {
            revert TransferNativeFailed();
        }
    }

    modifier costsCents(uint256 cents) {
        uint256 tinycents = toTiny(cents);
        uint256 requiredTinybars = tinycentsToTinybars(tinycents);
        if (msg.value < requiredTinybars) {
            revert InsufficientFee();
        }
        _;
    }

    // 100 centiCent == 1 cent; if multiplier == 0 then don't refund excess
    modifier costsCentiCents(uint256 centiCents, uint256 multiplier) {
        uint256 requiredTinybars = centiCentsToTinybars(centiCents);
        if (msg.value < requiredTinybars) {
            revert InsufficientFee();
        }

        if (multiplier > 0) {
            uint256 maxTinybars = multiplier * requiredTinybars;

            if (msg.value > maxTinybars) {
                uint256 excessTinybars = msg.value - maxTinybars;
                transferTinybars(excessTinybars, msg.sender);
            }
        }

        _;
    }
}
