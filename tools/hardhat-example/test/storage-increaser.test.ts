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
import { ethers } from 'hardhat';
import { StorageIncreaser, StorageIncreaser__factory } from '../types';

import {
  deployOverrides,
  getRandomNumber,
  getAllStorageUsed
} from './utils';

describe('StorageIncreaser', function () {

  let storageIncreaser: StorageIncreaser;

  before(async () => {

    const StorageIncreaser = (await ethers.getContractFactory('StorageIncreaser')) as StorageIncreaser__factory;

    storageIncreaser = await StorageIncreaser.deploy(deployOverrides);
    await storageIncreaser.deployed();

  });

  it('should be able to add N storage spaces to StorageIncrease contract and get used storage correctly using getStorageAt', async function () {

    const iterations = 2;

    for (let i = 0; i < iterations; i++) {

      console.log('-- iteration:', i);

      const { storageValues: startStorageValues, totalSizeKB: startTotalSizeKB } = await getAllStorageUsed(storageIncreaser);

      console.log('storageValues:', startStorageValues.length);
      console.log('totalSizeKB:', startTotalSizeKB);

      const increaseNumSpaces = getRandomNumber(1_000, 10_000);
      await storageIncreaser.increaseStorage(increaseNumSpaces);

      const { storageValues: endStorageValues, totalSizeKB: endTotalSizeKB } = await getAllStorageUsed(storageIncreaser);

      console.log('storageValues:', endStorageValues.length);
      console.log('totalSizeKB:', endTotalSizeKB);

      expect(endStorageValues.length).to.be.eq(startStorageValues.length + increaseNumSpaces, "storage did not increased as per expectation");

      const decreaseNumSpaces = getRandomNumber(1, (endStorageValues.length / 10)); // only allow to remove at most 1/10 of total storage

      await storageIncreaser.removeLastNElements(decreaseNumSpaces);

      const { storageValues: endAfterRemoveStorageValues, totalSizeKB: endAfterRemoveTotalSizeKB } = await getAllStorageUsed(storageIncreaser);

      expect(endAfterRemoveStorageValues.length).to.be.eq(endStorageValues.length - decreaseNumSpaces, "storage did not decrease as per expectation");

      console.log('storageValues:', endAfterRemoveStorageValues.length);
      console.log('totalSizeKB:', endAfterRemoveTotalSizeKB);

    }

  });

});
