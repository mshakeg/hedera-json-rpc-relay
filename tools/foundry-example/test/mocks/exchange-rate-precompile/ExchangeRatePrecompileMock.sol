// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'hedera-smart-contracts/exchange-rate-precompile/IExchangeRate.sol';

contract ExchangeRatePrecompileMock is IExchangeRate {

  address internal constant HTS_PRECOMPILE = address(0x168);

  function tinycentsToTinybars(uint256 tinycents) external override returns (uint256) {}

  function tinybarsToTinycents(uint256 tinybars) external override returns (uint256) {}

}