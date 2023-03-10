import { ContractFactory, Contract } from "ethers";
import { ethers, artifacts } from "hardhat";

export function getFactory(contract: string): Promise<ContractFactory> {
  return ethers.getContractFactory(contract);
};

export async function getBytecodeSize(contractName: string) {
  const artifact = await artifacts.readArtifact(contractName);
  return artifact.bytecode.length / 2; // Divide by 2 to get the size in bytes
}

export async function getAllStorageUsed(contract: Contract) {
  // Get the contract instance

  // Get the contract's storage layout by getting the number of storage slots
  const storageLayout = await ethers.provider.getStorageAt(contract.address, 0);

  // Calculate the number of storage slots based on the storage layout
  const numStorageSlots = ethers.BigNumber.from(storageLayout).toNumber();

  // Get the value of each storage slot
  const storageValues = [];
  let totalSize = 0;
  for (let i = 0; i < numStorageSlots; i++) {
    const storageValue = await contract.provider.getStorageAt(contract.address, i);
    storageValues.push(storageValue);

    const storageSize = ethers.utils.hexDataLength(storageValue);
    totalSize += storageSize;
  }

  const totalSizeKB = (totalSize / 1024).toFixed(2);

  return { storageValues, totalSizeKB };
}