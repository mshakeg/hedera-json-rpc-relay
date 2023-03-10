import { ContractFactory } from "ethers";
import { ethers, artifacts } from "hardhat";

export function getFactory(contract: string): Promise<ContractFactory> {
  return ethers.getContractFactory(contract);
};

export async function getBytecodeSize(contractName: string) {
  const artifact = await artifacts.readArtifact(contractName);
  return artifact.bytecode.length / 2; // Divide by 2 to get the size in bytes
}