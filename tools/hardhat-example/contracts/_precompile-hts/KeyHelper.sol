// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./HederaTokenService.sol";

contract KeyHelper is HederaTokenService {
    uint256 constant INHERIT_ACCOUNT_KEY = 1;
    uint256 constant CONTRACT_ID_KEY = 2;
    uint256 constant ED25519_KEY = 3;
    uint256 constant ECDSA_SECPK2561K1_KEY = 4;
    uint256 constant DELEGATABLE_CONTRACT_ID_KEY = 5;

    function createSingleKey(
        uint256 keyType,
        uint256 keyValueType,
        bytes memory key
    ) internal view returns (IHederaTokenService.TokenKey memory tokenKey) {
        tokenKey = IHederaTokenService.TokenKey(keyType, createKeyValueType(keyValueType, key, address(0)));
    }

    function createSingleKey(
        uint256 keyType,
        uint256 keyValueType,
        address key
    ) internal view returns (IHederaTokenService.TokenKey memory tokenKey) {
        tokenKey = IHederaTokenService.TokenKey(keyType, createKeyValueType(keyValueType, "", key));
    }

    function createKeyValueType(
        uint256 keyValueType,
        bytes memory key,
        address keyAddress
    ) internal view returns (IHederaTokenService.KeyValue memory keyValue) {
        if (keyValueType == INHERIT_ACCOUNT_KEY) {
            keyValue.inheritAccountKey = true;
        } else if (keyValueType == CONTRACT_ID_KEY) {
            keyValue.contractId = keyAddress;
        } else if (keyValueType == ED25519_KEY) {
            keyValue.ed25519 = key;
        } else if (keyValueType == ECDSA_SECPK2561K1_KEY) {
            keyValue.ECDSA_secp256k1 = key;
        } else if (keyValueType == DELEGATABLE_CONTRACT_ID_KEY) {
            keyValue.delegatableContractId = keyAddress;
        }
    }
}
