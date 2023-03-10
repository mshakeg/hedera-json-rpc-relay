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

  // Get the number of storage slots used by the contract
  const storageSlots = await ethers.provider.getStorageAt(contract.address, 0);

  const storageSlotsNum = parseInt(storageSlots, 16);

  // Loop through each storage slot and retrieve its value
  const storageValues = [];
  let totalSize = 0;
  for (let i = 0; i < storageSlotsNum; i++) {

    const storageValue = await contract.provider.getStorageAt(contract.address, i);
    const storageSize = ethers.utils.hexDataLength(storageValue);
    totalSize += storageSize;

    // If the storage value is a mapping or variable-sized array, retrieve its elements
    if (storageSize === 64) { // 32-byte mapping key + 32-byte value
      const mappingElements: {[key: string]: string} = {};
      const mappingIndex = i;
      const keySize = 32;
      const valueSize = 32;

      // Loop through each mapping key and retrieve its value
      let j = 0;
      while (true) {

        const keyStorageValue = await contract.provider.getStorageAt(contract.address, mappingIndex + j);
        if (keyStorageValue === "0x") {
          break; // End of mapping keys
        }
        const key = ethers.utils.hexlify(keyStorageValue);
        const valueStorageValue = await contract.provider.getStorageAt(contract.address, mappingIndex + j + 1);
        const value = ethers.utils.hexlify(valueStorageValue);
        mappingElements[key] = value;
        j += 2;
      }

      storageValues.push(mappingElements);
    } else if (storageSize > 64) { // variable-sized array
      const arrayElements = [];
      const arrayLocation = i;

      // Loop through each array element and retrieve its value
      for (let j = 0; j < 1000000; j++) { // assuming arrays are not longer than 1,000,000 elements

        const elementLocation = ethers.utils.solidityKeccak256(
          ["uint256", "uint256"],
          [arrayLocation, j]
        );
        const elementStorageValue = await contract.provider.getStorageAt(contract.address, elementLocation);
        if (elementStorageValue === "0x") {
          break; // End of array
        }
        const element = ethers.utils.hexlify(elementStorageValue);
        arrayElements.push(element);
      }

      storageValues.push(arrayElements);
    } else {
      storageValues.push(storageValue);
    }
  }

  // Calculate the total size in kilobytes
  const totalSizeKB = (totalSize / 1024).toFixed(2);

  return { storageValues, totalSizeKB };
}