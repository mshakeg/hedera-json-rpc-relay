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

import {ethers} from 'hardhat';

import {
  deployOverrides
} from '../utils';

import {
  Greeter__factory,
  SillyLargeContract__factory,
} from '../../types';

describe('Deploy Contracts', function() {

  it('Should be able to deploy Greeter', async function() {
    const Greeter = await ethers.getContractFactory('Greeter') as Greeter__factory;

    const greeter = await Greeter.deploy("hello world", deployOverrides);

    const deployRc = await greeter.deployTransaction.wait();
    const greeterAddress = deployRc.contractAddress;

    console.log('Greeter deployed to:', greeterAddress, '@block:', deployRc.blockNumber);
  });

  it('Should be able to deploy SillyLargeContract', async function() {
    const SillyLargeContract = await ethers.getContractFactory('SillyLargeContract') as SillyLargeContract__factory;

    const sillyLargeContract = await SillyLargeContract.deploy(deployOverrides);

    const deployRc = await sillyLargeContract.deployTransaction.wait();
    const sillyLargeContractAddress = deployRc.contractAddress;

    console.log('SillyLargeContract deployed to:', sillyLargeContractAddress, '@block:', deployRc.blockNumber);
  });

});
