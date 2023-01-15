import { Contract, ContractFactory, BigNumber, Signer } from "ethers";

import { FunctionArgs } from "./encoding";

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