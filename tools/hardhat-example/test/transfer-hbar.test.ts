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
import { BigNumber } from "ethers";

import {ethers} from 'hardhat';

import {
  ADDRESS_ZERO,
  getHbarValue,
  getGasPrice
} from './utils';

type ContractJSON = {
  abi: Array<object>,
  bytecode: string
}

describe('Transfer HBAR', function() {

  let gasPrice: BigNumber;

  before(async () => {
    const latestGasPrice = await getGasPrice();
    gasPrice = latestGasPrice;
  });

  it('CANNOT transfer(but should) to existing account at current gas price', async function() {

    const existingAccount = "0xA16e3686D5E12803B6e30c783Be10876dCEB8fc9";
    const signer = await ethers.provider.getSigner();
    const balanceBefore = await signer.getBalance();

    console.log(`Balance before: ${balanceBefore.toString()}`);

    const amount = getHbarValue(10);
    const tx = await signer.sendTransaction({ to: existingAccount, value: amount, gasPrice });
    console.log(`Transaction hash: ${tx.hash}`);

    const balanceAfter = await signer.getBalance();
    console.log(`Balance after: ${balanceAfter.toString()}`);

  });

  it('CANNOT transfer(but should) to new account at current gas price', async function() {

    const newAccount = "0xe15A8699a85558E570a0d0d5DE533bd23cE64d4A";
    const signer = await ethers.provider.getSigner();
    const balanceBefore = await signer.getBalance();

    console.log(`Balance before: ${balanceBefore.toString()}`);

    const amount = getHbarValue(10);
    const tx = await signer.sendTransaction({ to: newAccount, value: amount, gasPrice });
    console.log(`Transaction hash: ${tx.hash}`);

    const balanceAfter = await signer.getBalance();
    console.log(`Balance after: ${balanceAfter.toString()}`);

  });

  it('CAN transfer(but should) to existing account at 100x gas price', async function() {

    const existingAccount = "0xA16e3686D5E12803B6e30c783Be10876dCEB8fc9";
    const signer = await ethers.provider.getSigner();
    const balanceBefore = await signer.getBalance();

    console.log(`Balance before: ${balanceBefore.toString()}`);

    const amount = getHbarValue(10);
    const tx = await signer.sendTransaction({ to: existingAccount, value: amount, gasPrice: gasPrice.mul(100) });
    console.log(`Transaction hash: ${tx.hash}`);

    const balanceAfter = await signer.getBalance();
    console.log(`Balance after: ${balanceAfter.toString()}`);

  });

  it('CANNOT transfer(but should) to new account at 100x gas price', async function() {

    const newAccount = "0xe15A8699a85558E570a0d0d5DE533bd23cE64d4A";
    const signer = await ethers.provider.getSigner();
    const balanceBefore = await signer.getBalance();

    console.log(`Balance before: ${balanceBefore.toString()}`);

    const amount = getHbarValue(10);
    const tx = await signer.sendTransaction({ to: newAccount, value: amount, gasPrice: gasPrice.mul(100) });
    console.log(`Transaction hash: ${tx.hash}`);

    const balanceAfter = await signer.getBalance();
    console.log(`Balance after: ${balanceAfter.toString()}`);

  });

});
