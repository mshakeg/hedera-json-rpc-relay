import { BigNumberish } from "ethers";

export type FunctionParams =
  | boolean
  | number
  | string
  | BigNumberish
  | Array<number | string | BigNumberish>
  | undefined;

export type FunctionArgs = FunctionParams[];
