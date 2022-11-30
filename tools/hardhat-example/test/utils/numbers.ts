import { BigNumber } from "ethers";

const EDecimals = 18;
export const E18 = BigNumber.from(10).pow(EDecimals);

export function getHbarValue(hbars: number): BigNumber {
  return BigNumber.from(hbars).mul(E18);
}
