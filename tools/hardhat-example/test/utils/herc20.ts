import { BigNumber } from "ethers";

import { HERC20Util, HERC20Util__factory } from "../../types";
import { createToken } from "../api/core";
import { getFactory } from "./ethers";
import { deployToHedera } from "./hedera";
import { toSolidityAddress } from "./mono/formatting";

export class HERC20 {
  public tokenId: string;
  public address: string;
  private hERC20Util?: HERC20Util;

  constructor(_tokenId: string) {
    this.tokenId = _tokenId;
    this.address = toSolidityAddress(_tokenId);
  }

  public static async deploy(
    name: string,
    symbol: string,
    supply: BigNumber,
    decimals: number = 8,
    ownerAddress?: string
  ) {
    const tokenId = await createToken(name, symbol, decimals, supply.toNumber(), ownerAddress);

    if (tokenId) {
      return new HERC20(tokenId.toString());
    }
  }

  public async balanceOf(accountAddress: string): Promise<BigNumber> {
    const hERC20 = await this.getHERC20Util();
    return hERC20.balanceOf(this.address, accountAddress);
    // return balanceOf(this.address, accountAddress);
  }

  public async decimals(): Promise<number> {
    const hERC20 = await this.getHERC20Util();
    return hERC20.decimals(this.address);
    // return (await getTokenInfo(this.tokenId)).decimals;
  }

  public async name(): Promise<string> {
    const hERC20 = await this.getHERC20Util();
    return hERC20.name(this.address);
    // return (await getTokenInfo(this.tokenId)).name;
  }

  public async symbol(): Promise<string> {
    const hERC20 = await this.getHERC20Util();
    return hERC20.symbol(this.address);
    // return (await getTokenInfo(this.tokenId)).symbol;
  }

  private async getHERC20Util(): Promise<HERC20Util> {
    if (this.hERC20Util) {
      return this.hERC20Util;
    }

    const HERC20Util = (await getFactory("HERC20Util")) as HERC20Util__factory;

    this.hERC20Util = (await deployToHedera(HERC20Util)) as HERC20Util;

    return this.hERC20Util;
  }
}
