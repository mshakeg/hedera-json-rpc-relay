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
import fs from 'fs';

import {
  ADDRESS_ZERO,
  deployOverrides
} from './utils';

type ContractJSON = {
  abi: Array<object>,
  bytecode: string
}

describe('Deploy Problem Contract', function() {

  before(async () => {
  });

  it('should be able to deploy ProblemContract', async function() {

    const ProblemContractJSON = require('./json/ProblemContract.json') as ContractJSON;

    const ProblemContract = await ethers.getContractFactory(ProblemContractJSON.abi, ProblemContractJSON.bytecode);
    const problemContract = await ProblemContract.deploy(ADDRESS_ZERO, ADDRESS_ZERO, deployOverrides);

    const problemContractAddress = (await problemContract.deployTransaction.wait()).contractAddress;

    console.log('ProblemContractAddress:');
    console.log(problemContractAddress);

  });

});
