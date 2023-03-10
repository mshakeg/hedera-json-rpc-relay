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

import { expect } from 'chai';
import {ethers} from 'hardhat';
import { SillySmallContract } from '../types/contracts/SillySmallContract';

import {
  deployOverrides, getBytecodeSize
} from './utils';

describe('SillySmallContract', function() {

  const beforeDeployCount = 1;

  before(async () => {
    for (let i = 0; i< beforeDeployCount; i++) {
      const SillySmallContract = await ethers.getContractFactory('SillySmallContract');
      const sillySmallContract = await SillySmallContract.deploy(deployOverrides);
      console.log('deployed SillySmallContract:', i, 'to address:', sillySmallContract.address);
    }
  });

  it('should be able to deploy one more SillySmallContract', async function() {
    const SillySmallContract = await ethers.getContractFactory('SillySmallContract');
    const sillySmallContract = (await SillySmallContract.deploy(deployOverrides)) as SillySmallContract;
    console.log('deployed SillySmallContract to address', sillySmallContract.address);

    const count = await sillySmallContract.count();

    expect(count).to.be.eq(10);

    const size = await getBytecodeSize('SillySmallContract');

    console.log('size(in bytes):', size);
  });
});
