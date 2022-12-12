import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import {
  AccountId,
  ContractCreateFlow,
  ContractFunctionParameters,
  ContractInfoQuery,
  ContractUpdateTransaction,
  ContractId,
  Hbar,
  PublicKey,
  PrivateKey,
  Client,
} from "@hashgraph/sdk";

const operatorId = AccountId.fromString(process.env.TESTNET_OPERATOR_ID || "");
const operatorKey = PrivateKey.fromString(process.env.TESTNET_OPERATOR_PRIVATE_KEY || "");
const client = Client.forTestnet().setOperator(operatorId, operatorKey);

async function deployContract(
  _0xbytecode: string,
  {
    constructorParams,
    gasLimit = 1_000_000,
    value = 0, // in HBAR
    adminKey,
    stakeAccount,
    stakeNode,
  }: {
    constructorParams?: ContractFunctionParameters;
    gasLimit?: number;
    value?: number;
    adminKey?: PrivateKey;
    stakeAccount?: AccountId;
    stakeNode?: number;
  }
): Promise<[ContractId | null, string | undefined]> {
  if (stakeAccount && stakeNode) {
    throw new Error("Only specify either stakedAccountId or stakedNodeId, NOT BOTH");
  }

  let contractCreate = new ContractCreateFlow().setBytecode(_0xbytecode).setGas(gasLimit);

  if (value) {
    const initialBalance: Hbar = new Hbar(value);
    contractCreate = contractCreate.setInitialBalance(initialBalance);
  }

  // untested if this works
  if (constructorParams) {
    contractCreate = contractCreate.setConstructorParameters(constructorParams);
  }

  if (adminKey) {
    contractCreate = contractCreate.setAdminKey(adminKey);
  }

  if (stakeAccount) {
    contractCreate = contractCreate.setStakedAccountId(stakeAccount);
  }

  if (stakeNode) {
    contractCreate = contractCreate.setStakedNodeId(stakeNode);
  }

  const response = await contractCreate.execute(client);
  const contractDeployRx = await response.getReceipt(client);
  const contractId = contractDeployRx.contractId;
  const contractAddress = contractId?.toSolidityAddress();
  return [contractId, contractAddress];
}

async function getStakingInfoFcn(id: string | ContractId | null | undefined) {
  if (id) {
    const accountInfo = await new ContractInfoQuery().setContractId(id).execute(client);
    console.log(`- Staking info:`);
    console.log(`-- stakedAccountId: ${accountInfo?.stakingInfo?.stakedAccountId}`);
    console.log(`-- stakedNodeId: ${accountInfo?.stakingInfo?.stakedNodeId}`);
    console.log(`-- declineStakingReward: ${accountInfo?.stakingInfo?.declineStakingReward}`);
  }
}

const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  console.log("Deploy NativeStaker & StakeToNativeStaker");

  const nativeStakerBytecode = (await hre.ethers.getContractFactory("NativeStaker")).bytecode;
  const stakeToNativeStakerBytecode = (await hre.ethers.getContractFactory("StakeToNativeStaker")).bytecode;

  const [nativeStakerId, nativeStakerAddress] = await deployContract(nativeStakerBytecode, {
    adminKey: operatorKey,
    stakeNode: 4,
  });

  console.log(`NativeStaker: ${nativeStakerId}`);
  console.log(`NativeStaker Address: ${nativeStakerAddress}`);
  await getStakingInfoFcn(nativeStakerId);

  if (!nativeStakerAddress) {
    throw Error("No NativeStaker");
  }

  const stakeToNativeStakerConstructorParams = new ContractFunctionParameters().addAddress(nativeStakerAddress);

  const [stakeToNativeStakerId, stakeToNativeStakerAddress] = await deployContract(stakeToNativeStakerBytecode, {
    constructorParams: stakeToNativeStakerConstructorParams,
    stakeAccount: AccountId.fromString("" + nativeStakerId),
    gasLimit: 6_000_000,
    value: 30,
  });

  console.log(`StakeToNativeStaker: ${stakeToNativeStakerId}`);
  console.log(`StakeToNativeStaker Address: ${stakeToNativeStakerAddress}`);
  await getStakingInfoFcn(stakeToNativeStakerId);

  // Update an existing smart contract (must have admin key)
  // const updateStatus = await contractUpdaterFcn(contractId, operatorKey, null, 4, true);
  // console.log(`\n- 2.2) ${updateStatus}: Updated contract ${contractId}:`);
  // await getStakingInfoFcn(contractId);
};

export default deployFunction;

deployFunction.tags = ["NativeStaker"];
