// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';

import '../mocks/hts-precompile/HtsPrecompileMock.sol';

/// for testing actions common to both HTS token types i.e FUNGIBLE and NON_FUNGIBLE
/// also has common constants for both HTS token types
abstract contract HederaTokenUtils is Test {

    address constant htsPrecompileAddress = address(0x167);

    HtsPrecompileMock htsPrecompile = HtsPrecompileMock(htsPrecompileAddress);

    function _setUpHtsPrecompileMock() internal {
        HtsPrecompileMock htsPrecompileMock = new HtsPrecompileMock();
        bytes memory code = address(htsPrecompileMock).code;
        vm.etch(htsPrecompileAddress, code);
    }

}
