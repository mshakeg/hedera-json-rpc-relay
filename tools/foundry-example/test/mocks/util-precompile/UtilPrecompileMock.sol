// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'hedera-smart-contracts/util-precompile/IPrngSystemContract.sol';

contract UtilPrecompileMock is IPrngSystemContract {

  address internal constant UTIL_PRECOMPILE = address(0x169);

  function getPseudorandomSeed() external returns (bytes32) {}

}