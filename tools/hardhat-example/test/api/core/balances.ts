import { BigNumber } from "@ethersproject/bignumber";

import {
  AccountBalance,
  AccountBalanceQuery, AccountId, ContractId,
} from "@hashgraph/sdk";
import { getClient } from "../../utils/hedera";
import { toAccountId, toContractId } from "../../utils/mono/formatting";

import { getAccountInfo, getContractInfo } from "../mirror";

const parseAccountBalances = (response: AccountBalance) => {
  const parsedResponse: {[key: string]: Number} = {};

  const tokens = response.tokens;

  if (tokens) {
    for (const token of tokens) {
      const [tokenId, balance] = token.toString().split(",");

      parsedResponse[tokenId] = Number(balance);
    }

    parsedResponse["0.0.0"] = Number(response.hbars._valueInTinybar.toString());
  }

  return parsedResponse;
};

export const queryAccountTokenBalance = async (entityId: string) => {
  try {
    const contractInfo = await getContractInfo(entityId);

    const isContract = contractInfo.ok;

    let contractId!: ContractId;
    let accountId!: AccountId;

    if (isContract) {
      contractId = toContractId(entityId);
    } else {
      accountId = AccountId.fromString(entityId);
    }

    const balanceQuery = new AccountBalanceQuery()

    if (isContract) {
      balanceQuery.setContractId(contractId);
    } else {
      balanceQuery.setAccountId(accountId);
    }

    const client = getClient();

    const balance = await balanceQuery.execute(client);

    return {
      ok: true,
      data: parseAccountBalances(balance)
    };

  } catch (error: any) {
    // console.error(error);

    return {
      ok: false,
      status: error.status?._code,
    };
  }
};

export const balanceOf = async (tokenAddress: string, accountAddress: string): Promise<BigNumber> => {
  const tokenId = toAccountId(tokenAddress);

  const accountRes = await getAccountInfo(accountAddress);

  const accountId = accountRes.data.account;

  const response = await queryAccountTokenBalance(accountId);

  if (response.ok) {
    const tokenBalance = response.data?.[tokenId] || 0;
    // cast number to string to avoid overflow issue
    return BigNumber.from(`${tokenBalance}`);
  }
  throw new Error('Failed to get sdk balance!')
};
