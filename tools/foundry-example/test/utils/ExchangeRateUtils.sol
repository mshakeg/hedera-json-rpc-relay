// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';

import '../mocks/exchange-rate-precompile/ExchangeRatePrecompileMock.sol';
import './CommonUtils.sol';
import '../libraries/Constants.sol';

/// for testing actions of the exchange rate precompiled/system contract
abstract contract ExchangeRateUtils is Test, CommonUtils, Constants {

    ExchangeRatePrecompileMock utilPrecompile = ExchangeRatePrecompileMock(EXCHANGE_RATE_PRECOMPILE);

    function _setUpExchangeRatePrecompileMock() internal {
        ExchangeRatePrecompileMock exchangeRatePrecompileMock = new ExchangeRatePrecompileMock();
        bytes memory code = address(exchangeRatePrecompileMock).code;
        vm.etch(Constants.EXCHANGE_RATE_PRECOMPILE, code);
    }
}
