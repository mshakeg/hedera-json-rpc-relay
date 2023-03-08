import { BigNumber, BigNumberish } from "ethers";

import { ethers } from "hardhat";

const EDecimals = 18;

const HDecimals = 8;

const HE_Decimals = 10; // since ETH has 18 and HBAR has 8

export const E8 = BigNumber.from(10).pow(HDecimals);

export const E10 = BigNumber.from(10).pow(HE_Decimals);

export const E18 = BigNumber.from(10).pow(EDecimals);

export const MAX_FEE = BigNumber.from(10000);

export const BASE_TEN = 10;

export function getBigNumber(amount: BigNumberish, decimals = HDecimals): BigNumber {
  return BigNumber.from(amount).mul(BigNumber.from(BASE_TEN).pow(decimals));
}

export function getHbarValue(hbars: number): BigNumber {
  return BigNumber.from(hbars).mul(E18);
}

export async function getGasPrice(): Promise<BigNumber> {
  const networkProvider = ethers.provider;
  return networkProvider.getGasPrice();
}