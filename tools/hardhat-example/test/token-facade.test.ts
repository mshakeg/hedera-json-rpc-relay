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
import { ContractTransaction, ContractReceipt } from 'ethers';
import { ethers } from 'hardhat';
import { IHRC__factory } from '../types';

import {
  defaultOverrides,
} from './utils';

describe('HTS Facade', function () {

  it('should be to associate and dissociate from a token', async function () {

    const accounts = await ethers.getSigners();
    const signer = accounts[0];

    console.log("signer:", signer.address);

    const tokenAddress = '0x0000000000000000000000000000000000437fde' // testnet token
    const hrcContract = IHRC__factory.connect(tokenAddress, signer);

    const associateTx: ContractTransaction = await hrcContract.associate(defaultOverrides);
    console.log("associate hash:", associateTx.hash);

    const associateRc: ContractReceipt = await associateTx.wait(5);

    expect(associateRc.status).to.be.eq(1); // 1 is success

    const dissociateTx: ContractTransaction = await hrcContract.dissociate(defaultOverrides);
    console.log("dissociate hash:", dissociateTx.hash);

    const dissociateRc: ContractReceipt = await dissociateTx.wait(5);

    expect(dissociateRc.status).to.be.eq(1); // 1 is success

  });

});
