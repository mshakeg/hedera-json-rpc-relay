import { ethers, Contract, ContractFactory, BigNumber, Signer } from "ethers";
import hre from "hardhat";

import { FunctionArgs } from "./encoding";

import { utils } from "@hashgraph/hethers";
import { AccountId, PrivateKey, Client } from "@hashgraph/sdk";

import { SdkAccounts } from "./accounts";
import { HederaNetwork } from "./networks";

export async function getHederaDeployAddress(contract: Contract): Promise<string> {
  return (await contract.deployTransaction.wait()).contractAddress;
}

export async function deployToHedera(
  Contract: ContractFactory,
  args: FunctionArgs = [],
  overrides: {
    from?: Signer;
    gasLimit?: number;
    value?: BigNumber;
  } = {
    gasLimit: 1_000_000,
  }
): Promise<Contract> {
  const contract = await Contract.deploy(...args, overrides);
  const contractAddress = await getHederaDeployAddress(contract); // hedera contract address corresponds with the account id not the create1 address on typical evm chains
  return Contract.attach(contractAddress);
}

export type Wallet = ethers.Wallet;

export const getActiveProvider = (): ethers.providers.JsonRpcProvider => {
  return hre.ethers.provider;
};

export const getWallet = (pvKey: string): Wallet => {
  return new hre.ethers.Wallet(pvKey, getActiveProvider());
};

export const getOperatorPvKey = (): string => {
  return String(process.env.OPERATOR_PRIVATE_KEY);
};

export const getOperatorWallet = (): Wallet => {
  return getWallet(getOperatorPvKey());
};

export const showBalance = async (address: string, provider?: ethers.providers.JsonRpcProvider) => {
  // const provider = new hre.ethers.providers.JsonRpcProvider(process.env.RELAY_ENDPOINT);
  // const wallet = new hre.ethers.Wallet(String(process.env.OPERATOR_PRIVATE_KEY), provider);

  // const balance = (await wallet.getBalance()).toString();
  // console.log(`The address ${wallet.address} has ${balance} tinybars`);

  if (!provider) {
    provider = getActiveProvider();
  }

  const balance = (await provider.getBalance(address)).toString();
  console.log(`The address ${address} has ${balance} tinybars`);

  return balance;
};

export const transferHbars = async (amount = 100_000_000_000, receiverAddress?: string) => {
  const provider = new hre.ethers.providers.JsonRpcProvider(process.env.RELAY_ENDPOINT);
  const wallet = new hre.ethers.Wallet(String(process.env.OPERATOR_PRIVATE_KEY), provider);
  const walletReceiver = new hre.ethers.Wallet(String(process.env.RECEIVER_PRIVATE_KEY), provider);

  if (receiverAddress) {
    console.log(`Balance before tx: ${await provider.getBalance(receiverAddress)}`);
  } else {
    console.log(`Balance before tx: ${await walletReceiver.getBalance()}`);
  }

  // Keep in mind that TINYBAR to WEIBAR coefficient is 10_000_000_000
  await wallet.sendTransaction({
    to: receiverAddress || walletReceiver.address,
    value: amount, // 10 tinybars
  });
  console.log(`Balance after tx: ${await walletReceiver.getBalance()}`);
};

export const getAccountIdFromAddress = (contractAddress: string): string => {
  const account = utils.getAccountFromAddress(contractAddress);

  return utils.asAccountString(account);
};

export const deployContract = async (contractName: string, params: Array<any>, sender: Wallet): Promise<string> => {
  const Contract = await hre.ethers.getContractFactory(contractName, sender);
  const contract = await Contract.deploy(...params);
  const contractAddress = (await contract.deployTransaction.wait()).contractAddress;
  const contractId = utils.getAccountFromAddress(contractAddress);

  console.log(`Contract id: ${utils.asAccountString(contractId)}`);
  console.log(`Contract deployed to: ${contractAddress}`);

  return contractAddress;
};

export const contractViewCall = async (
  contractName: string,
  address: string,
  functionName: string,
  params: Array<any> = [],
  sender?: Wallet
) => {
  if (!sender) {
    sender = getOperatorWallet();
  }

  const contract = await hre.ethers.getContractAt(contractName, address, sender);
  const callRes = await contract[functionName](...params); // callStatic

  return callRes;
};

export const contractCall = async (
  contractName: string,
  address: string,
  functionName: string,
  params: Array<any> = [],
  sender: Wallet,
  value: number | BigNumber = 0
) => {
  const contract = await hre.ethers.getContractAt(contractName, address, sender);
  const callTx = await contract[functionName](...params, {
    value,
  });

  return callTx;
};

export const getNetworkCreds = (): {
  accountId: string;
  privateKey: string;
} => {
  const network = hre.network.name as HederaNetwork;

  const { accountId, privateKey } = SdkAccounts[network];

  return {
    accountId,
    privateKey,
  };
};

export const getOperator = (
  _accountId?: string,
  _privateKey?: string,
  network?: HederaNetwork
): { accountId: AccountId; privateKey: PrivateKey } => {
  let accountId!: string;
  let privateKey!: string;

  if (network) {
    const { accountId: __accountId, privateKey: __privateKey } = SdkAccounts[network];

    accountId = __accountId;
    privateKey = __privateKey;
  } else {
    accountId = _accountId || "";
    privateKey = _privateKey || "";
  }

  return {
    accountId: AccountId.fromString(accountId),
    privateKey: PrivateKey.fromString(privateKey),
  };
};

export const getClient = (accountCreds?: { accountId: string; privateKey: string }): Client => {
  let network = hre.network.name;

  if (!network) {
    console.warn("WARNING: reading NETWORK from .env");
    network = process.env.NETWORK || "h_local";
    console.warn(`WARNING: fallback network: ${network}`);
  }

  let client!: Client;

  switch (network) {
    case "h_local":
      const node = { "127.0.0.1:50211": new AccountId(3) };
      client = Client.forNetwork(node);
      client.setMirrorNetwork("127.0.0.1:5600");
      break;
    case "h_testnet":
      client = Client.forTestnet();
      break;
    case "h_mainnet":
      client = Client.forMainnet();
      break;
    default:
      throw new Error("Invalid Network in getClient");
  }

  const { accountId, privateKey } = getOperator(accountCreds?.accountId, accountCreds?.privateKey, network);

  return client.setOperator(accountId, privateKey);
};
