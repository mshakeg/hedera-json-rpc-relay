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

import { ethers } from 'hardhat';

import {
  getAllStorageUsed
} from './utils';

describe('Get Contract Storage Size', function () {

  it('get contract size', async function () {

    // const contractAddress = '0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640'; // UniV3 usdc/weth/0.05% pool
    const contractAddress = '0x3Db0338922CDE54A66E0c585011249915d32d225';
    const contract = new ethers.Contract(contractAddress, [], ethers.provider);

    const { storageValues, totalSizeKB } = await getAllStorageUsed(contract);

    console.log({ storageValuesLength: storageValues.length, totalSizeKB });

  });

});
