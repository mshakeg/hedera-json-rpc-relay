import { BigNumber } from "ethers";

import { ethers } from "hardhat";

const EDecimals = 18;
export const E18 = BigNumber.from(10).pow(EDecimals);

export function getHbarValue(hbars: number): BigNumber {
  return BigNumber.from(hbars).mul(E18);
}

export async function getGasPrice(): Promise<BigNumber> {
  const networkProvider = ethers.provider;
  return networkProvider.getGasPrice();
}