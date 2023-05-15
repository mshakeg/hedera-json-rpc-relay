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

import { expect } from "chai";
import { Contract } from 'ethers';
import {ethers} from 'hardhat';

import { Caller, Caller__factory, LowLevelReceiver, LowLevelReceiver__factory } from '../types';

import {
  ADDRESS_ZERO,
  deployOverrides,
  deployToHedera
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

describe('LowLevelCall', function() {

  let caller: Caller;
  let lowLevelReceiver: LowLevelReceiver;

  // random invalid(non-existent) LowLevelReceiver address
  // const invalidLowLevelReceiverAddress = '0xd9145CCE52D386f254917e481eB44e9943F39138';
  const invalidLowLevelReceiverAddress = ADDRESS_ZERO;

  before(async () => {

    const Caller = (await ethers.getContractFactory("Caller")) as Caller__factory;
    const LowLevelReceiver = (await ethers.getContractFactory("LowLevelReceiver")) as LowLevelReceiver__factory;

    caller = (await deployToHedera(Caller)) as Caller;
    lowLevelReceiver = (await deployToHedera(LowLevelReceiver)) as LowLevelReceiver;

  });

  it('should be able to testCallFoo on a valid LowLevelReceiver', async function() {

    const tx = await caller.testCallFoo(lowLevelReceiver.address);
    const rc = await tx.wait();

    // const responseEvent = rc.events?.find((event) => event.event === "Response");

    expect(rc.status).to.be.eq(1);

  });

  it('should ALSO be able to testCallFoo on a INVALID LowLevelReceiver', async function() {

    const tx = await caller.testCallFoo(invalidLowLevelReceiverAddress);
    const rc = await tx.wait();
    expect(rc.status).to.be.eq(1);

  });

  it('should be able to testCallViewCall on a valid LowLevelReceiver', async function() {

    const result = await caller.callStatic.testCallViewCall(lowLevelReceiver.address);
    expect(result?.success).to.be.eq(true);

  });

  it('should ALSO be able to testCallViewCall on a INVALID LowLevelReceiver', async function() {

    const result = await caller.callStatic.testCallViewCall(invalidLowLevelReceiverAddress);
    expect(result?.success).to.be.eq(true);

  });

  it('should confirm valid contract', async function() {

    const result = await caller.isContract(lowLevelReceiver.address);
    expect(result).to.be.eq(true);

  });

  it('should confirm invalid contract', async function() {

    const result = await caller.isContract(invalidLowLevelReceiverAddress);
    expect(result).to.be.eq(false);

  });

  it('should confirm valid contract via tx', async function() {

    const tx = await caller.isContractTx(lowLevelReceiver.address);

    const rc = await tx.wait();

    const responseEvent = rc.events?.find((event) => event.event === "Response");

    expect(responseEvent).to.not.be.eq(undefined);
    expect(responseEvent?.args!.success).to.be.eq(true);

  });

  it('should confirm invalid contract via tx', async function() {

    const tx = await caller.isContractTx(invalidLowLevelReceiverAddress);

    const rc = await tx.wait();

    const responseEvent = rc.events?.find((event) => event.event === "Response");

    expect(responseEvent).to.not.be.eq(undefined);
    expect(responseEvent?.args!.success).to.be.eq(false);

  });

});
