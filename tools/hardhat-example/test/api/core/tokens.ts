import {
  TokenAssociateTransaction,
  TokenCreateTransaction,
  TokenType,
  TokenInfo,
  TokenId,
  TokenSupplyType,
  TokenInfoQuery,
  TransferTransaction,
  AccountId,
  PrivateKey,
  PublicKey,
  Client,
} from "@hashgraph/sdk";

import { getNetworkCreds, getOperator, getClient } from "../../utils/hedera";
import { Accounts } from "../../utils/accounts";

import { getAccountInfo } from "../mirror/accounts";

import { queryAccountTokenBalance } from "./balances";
import { toAccountId } from "../../utils/mono/formatting";

export const getClientFromOperatorIdOrAddress = async (
  operatorIdOrAddress: string
): Promise<{
  _accountId: string;
  _privateKey: string;
  client: Client;
  accountId: AccountId;
  privateKey: PrivateKey;
  publicKey: PublicKey;
}> => {
  const _accountId: string =
    operatorIdOrAddress === "0.0.2"
      ? "0.0.2"
      : (await getAccountInfo(operatorIdOrAddress)).data.account;

  let _privateKey = Accounts[_accountId];

  const { accountId, privateKey } = getOperator(_accountId, _privateKey);

  const publicKey = privateKey.publicKey;

  const client = getClient({ accountId: _accountId, privateKey: _privateKey });

  return {
    _accountId,
    _privateKey,
    client,
    accountId,
    privateKey,
    publicKey,
  };
};

export const createToken = async (
  tokenName: string,
  tokenSymbol: string,
  decimals: number,
  initialBaseSupply: number,
  _ownerIdOrAddress?: string
): Promise<TokenId | null> => {
  if (!_ownerIdOrAddress) {
    _ownerIdOrAddress = getNetworkCreds().accountId;
  }

  const { client, accountId, privateKey, publicKey } =
    await getClientFromOperatorIdOrAddress(_ownerIdOrAddress);

  let tokenCreateTx = await new TokenCreateTransaction()
    .setTokenName(tokenName)
    .setTokenSymbol(tokenSymbol)
    .setTokenType(TokenType.FungibleCommon)
    .setDecimals(decimals)
    .setSupplyType(TokenSupplyType.Infinite)
    .setInitialSupply(initialBaseSupply)
    .setTreasuryAccountId(accountId)
    .setAdminKey(publicKey)
    .setSupplyKey(publicKey)
    .setWipeKey(publicKey)
    .setAutoRenewAccountId(accountId);

  tokenCreateTx = tokenCreateTx.freezeWith(client);

  const tokenCreateSign = await tokenCreateTx.sign(privateKey);
  const tokenCreateSubmit = await tokenCreateSign.execute(client);
  const tokenCreateRx = await tokenCreateSubmit.getReceipt(client);
  return tokenCreateRx.tokenId;
};

export const getTokenInfo = async (tokenId: string): Promise<TokenInfo> => {
  const client = getClient();

  const query = new TokenInfoQuery().setTokenId(tokenId);

  return query.execute(client);
};

export const associateToken = async (
  tokenIdOrAddress: string,
  accountId: string
) => {
  try {
    const tokenId = toAccountId(tokenIdOrAddress);
    const privateKey = Accounts[accountId];

    const client = getClient({ accountId, privateKey });

    let associateTx = await new TokenAssociateTransaction()
      .setAccountId(accountId)
      .setTokenIds([tokenId])
      .freezeWith(client)
      .sign(PrivateKey.fromString(privateKey));

    let associateTxSubmit = await associateTx.execute(client);
    let associateRx = await associateTxSubmit.getReceipt(client);

    return {
      ok: true,
      result: {
        associateRx,
      },
    };
  } catch (error: any) {
    console.warn(error);

    return {
      ok: false,
      status: error.status?._code,
    };
  }
};

export const autoAssociate = async (
  tokenIdOrAddress: string,
  accountIdOrAddress: string
) => {
  const tokenId = toAccountId(tokenIdOrAddress);

  const accountRes = await getAccountInfo(accountIdOrAddress);

  const accountId = accountRes.data.account;

  const response = await queryAccountTokenBalance(accountId);

  const notAssociated = response.data?.[tokenId] === undefined;

  if (notAssociated) {
    console.log("associating", accountId, "with", tokenId);
    await associateToken(tokenId, accountId);
  }
};

export const transferToken = async (
  receiverIdOrAddress: string,
  tokenAddressOrId: string,
  amount: number,
  _ownerIdOrAddress?: string
) => {
  try {
    if (!_ownerIdOrAddress) {
      _ownerIdOrAddress = getNetworkCreds().accountId;
    }

    const tokenId = toAccountId(tokenAddressOrId);

    const receiverAccountId: string = (
      await getAccountInfo(receiverIdOrAddress)
    ).data.account;

    const { accountId, client } = await getClientFromOperatorIdOrAddress(
      _ownerIdOrAddress
    );

    //Create the transfer transaction
    const sendToken = await new TransferTransaction()
      .addTokenTransfer(tokenId, accountId, -amount)
      .addTokenTransfer(tokenId, receiverAccountId, amount)
      .execute(client);

    //Verify the transaction reached consensus
    const transactionReceipt = await sendToken.getReceipt(client);

    // console.log('txId:', sendToken.transactionId.toString())
    // console.log('transferring', amount, tokenId, 'to', receiverIdOrAddress)
    // const contractExecuteRec = await new TransactionRecordQuery().setTransactionId(txId).execute(client);

    return {
      ok: true,
      result: {
        transactionReceipt,
      },
    };
  } catch (error: any) {
    console.warn(error);

    return {
      ok: false,
      status: error.status?._code,
    };
  }
};
