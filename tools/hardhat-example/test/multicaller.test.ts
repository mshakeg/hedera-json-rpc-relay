/*-
 *
 * Hedera JSON RPC Relay - Hardhat Example
 *
 * Copyright (C) 2022 Hedera Hashgraph, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import { BigNumberish, Contract } from 'ethers';
import {ethers} from 'hardhat';
import { solidityPack } from "ethers/lib/utils";
import { defaultAbiCoder } from "@ethersproject/abi";

import {
  Multicaller__factory,
  Multicaller,
  VeryLongInputStruct
} from '../types';

import {
  deployOverrides
} from './utils';

// type SuccessPromiseSettledResults = PromiseSettledResult<Contract>[]
type SuccessContractPromiseSettledResults = {
  status: string,
  value: Contract
}[];

const SettledStatus = {
  fulfilled: "fulfilled",
  rejected: "rejected"
};

describe('Multicaller', function() {

  let multicaller: Multicaller;

  function encodeProcessShortInput(a: BigNumberish): string {
    return solidityPack(
      ["bytes4", "bytes"],
      [
        multicaller.interface.getSighash("processShortInput(uint256)"),
        defaultAbiCoder.encode(["uint256"], [a]),
      ]
    );
  }

  function encodeProcessLongInput(a: BigNumberish, b: BigNumberish, c: BigNumberish, d: BigNumberish, e: BigNumberish, f: BigNumberish, g: BigNumberish): string {
    return solidityPack(
      ["bytes4", "bytes"],
      [
        multicaller.interface.getSighash("processLongInput(uint256,uint256,uint256,uint256,uint256,uint256,uint256)"),
        defaultAbiCoder.encode(["uint256", "uint256", "uint256", "uint256", "uint256", "uint256", "uint256"], [a, b, c, d, e, f, g]),
      ]
    );
  }

  function encodeProcessVeryLongInput(veryLongInputStruct: VeryLongInputStruct): string {
    const processVeryLongInputEncoding = multicaller.interface.encodeFunctionData("processVeryLongInput", [veryLongInputStruct]);
    return processVeryLongInputEncoding;
  }

  async function multicallProcessLongInput(iterations: number) {

    const data: string[] = [];

    for (let i = 0; i < iterations; i++) {

      const [a, b, c, d, e, f, g] = [1, 2, 3, 4, 5, 6, 7].map(num => num * i);
      data.push(encodeProcessLongInput(a, b, c, d, e, f, g));
    }

    console.log('data length:', data.length);

    const res = await multicaller.callStatic.multicall(data, {
      gasLimit: 15_000_000
    });

    console.log('res length:', res.length);

  }

  before(async () => {

    const Multicaller = (await ethers.getContractFactory('Multicaller')) as Multicaller__factory;

    const _multicaller = await Multicaller.deploy(deployOverrides);
    const deployRc = await _multicaller.deployTransaction.wait();
    const multicallerAddress = deployRc.contractAddress;

    console.log("multicallerAddress:", multicallerAddress);

    multicaller = Multicaller.attach(multicallerAddress);

  });

  it('should be able to multicall processShortInput', async function() {

    const iterations = 3;
    const data: string[] = [];

    for (let i = 0; i < iterations; i++) {
      data.push(encodeProcessShortInput(i));
    }

    const res = await multicaller.callStatic.multicall(data, {
      gasLimit: 5_000_000
    });

    console.log(res);
  });

  it('should be able to make multicall 42 or less processLongInput calls', async function() {

    await multicallProcessLongInput(42);

  });

  // fails on testnet on 43+ calls
  it('should be able to make 43 or more multicall processLongInput calls', async function() {

    await multicallProcessLongInput(43);

  });

  it('should be able to make 1637 or less multicall processLongInput calls', async function() {

    await multicallProcessLongInput(1637);

  });

  // fails on local on 1638+
  it('should be able to make 1638 or more multicall processLongInput calls', async function() {

    await multicallProcessLongInput(1638);

  });

  // it('should be able to multicall processVeryLongInput', async function() {

  //   const iterations = 1600;
  //   const data: string[] = [];

  //   for (let x = 0; x < iterations; x++) {

  //     const [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o] = [1, 2, 3, 4, 5, 6, 7, 9, 9, 10, 11, 12, 13, 14, 15, 16].map(num => num * x);
  //     const veryLongInputStruct: VeryLongInputStruct = {
  //       a,
  //       b,
  //       c,
  //       d,
  //       e,
  //       f,
  //       g,
  //       h,
  //       i,
  //       j,
  //       k,
  //       l,
  //       m,
  //       n,
  //       o,
  //     }

  //     data.push(encodeProcessVeryLongInput(veryLongInputStruct));
  //   }

  //   console.log('data length:', data.length);

  //   const res = await multicaller.callStatic.multicall(data, {
  //     gasLimit: 15_000_000
  //   });

  //   console.log('res length:', res.length);

  // });
});
