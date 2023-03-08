import { Validation } from "./validation";
import { ContractId } from "@hashgraph/sdk";

import { utils } from "ethers";

export const toAccountId = (accountNum: string) => {
  if (typeof accountNum === "string") {
    if (accountNum.startsWith("0.0.")) {
      return accountNum;
    }

    if (Validation.isValidEvmAddress(accountNum)) {
      return `0.0.${parseInt(accountNum)}`;
    }
  }

  return `0.0.${accountNum}`;
};

export const toAccountNum = (accountId: string) => {
  return parseInt(accountId.replace("0.0.", ""));
};

export const toContractId = (contract: string) => {
  if (typeof contract === "string") {
    if (contract.startsWith("0.0.")) {
      return ContractId.fromString(contract);
    } else if (contract.startsWith("0x")) {
      return ContractId.fromEvmAddress(0, 0, contract.substring(2));
    } else if (contract.length === 40) {
      // raw evm address that doesn't start with 0x

      return ContractId.fromEvmAddress(0, 0, contract);
    }
  }

  throw new Error("Invalid contract");

};

export const toSolidityAddress = (entity: string) => {
  const isHex = typeof entity === "string" && entity.startsWith("0x");

  let contractId!: ContractId;

  if (Validation.isValidHederaId(entity)) {
    contractId = toContractId(entity);
  } else if (Validation.isValidNum(entity)) {
    contractId = toContractId(toAccountId(entity));
  }

  let hex = entity;

  if (!isHex) {

    let evmString: string;

    if (typeof contractId === "string") {
      evmString = entity;
    } else {
      evmString = contractId.toSolidityAddress();
    }

    hex = "0x" + evmString;
  }

  return utils.getAddress(hex);
};
