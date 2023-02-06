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

import { Contract } from 'ethers';
import {ethers} from 'hardhat';

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

describe('SillyLargeContract', function() {

  const beforeDeployCount = 1;
  const testDeployCount = 10;
  const parallelDeployCount = 2;

  before(async () => {

    // deploy "deployCount" number of SillyLargeContract

    for (let i = 0; i< beforeDeployCount; i++) {

      const SillyLargeContract = await ethers.getContractFactory('SillyLargeContract');

      const sillyLargeContract = await SillyLargeContract.deploy(deployOverrides);

      console.log("computed create1 address:", sillyLargeContract.address);

      const deployRc = await sillyLargeContract.deployTransaction.wait();
      const sillyLargeContractAddress = deployRc.contractAddress;

      console.log('deployed SillyLargeContract:', i, 'to address:', sillyLargeContractAddress);

    }

  });

  it('should be able to deploy many SillyLargeContract in parallel', async function() {

    const deployPromises = [];

    for (let i = 0; i < parallelDeployCount; i++) {

      const SillyLargeContract = await ethers.getContractFactory('SillyLargeContract');

      deployPromises.push(SillyLargeContract.deploy(deployOverrides));
    }

    console.log('waiting for all to settle');

    const responses = (await Promise.allSettled(deployPromises)) as SuccessContractPromiseSettledResults;

    for (const res of responses) {
      if (res.status = SettledStatus.fulfilled) {
        console.log("computed create1 address:", res.value.address);
        const deployRc = await res.value.deployTransaction.wait();
        const sillyLargeContractAddress = deployRc.contractAddress;
        console.log('deployed SillyLargeContract to address:', sillyLargeContractAddress);
      } else {
        console.log('res:')
        console.log(res)
      }
    }

  });

  it('should be able to deploy many more SillyLargeContract', async function() {

    for (let i = 0; i < testDeployCount; i++) {

      const SillyLargeContract = await ethers.getContractFactory('SillyLargeContract');

      const sillyLargeContract = await SillyLargeContract.deploy(deployOverrides);

      console.log("computed create1 address:", sillyLargeContract.address);

      const deployRc = await sillyLargeContract.deployTransaction.wait();
      const sillyLargeContractAddress = deployRc.contractAddress;

      console.log('deployed SillyLargeContract:', i, 'to address:', sillyLargeContractAddress);

    }

  });

  it('should be able to deploy one more SillyLargeContract', async function() {

    const SillyLargeContract = await ethers.getContractFactory('SillyLargeContract');

    const sillyLargeContract = await SillyLargeContract.deploy(deployOverrides);

    console.log("computed create1 address:", sillyLargeContract.address);

    const deployRc = await sillyLargeContract.deployTransaction.wait();
    const sillyLargeContractAddress = deployRc.contractAddress;

    console.log('deployed SillyLargeContract to address', sillyLargeContractAddress);

  });
});
