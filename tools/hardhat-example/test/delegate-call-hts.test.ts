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
  RouterHts__factory,
  PrecompileHts__factory,
  SuperRouterHts__factory
} from '../types';

import {
  deployOverrides
} from './utils';

describe('DelegateCall Test', function() {

  it('show logs', async function() {
    const CoreHts = await ethers.getContractFactory('CoreHts');
    const coreHts = await CoreHts.deploy(deployOverrides);
    await coreHts.deployed();

    const PrecompileHts = (await ethers.getContractFactory('PrecompileHts')) as PrecompileHts__factory;
    const precompileHts = await PrecompileHts.deploy(deployOverrides);
    await precompileHts.deployed();

    const RouterHts = (await ethers.getContractFactory('RouterHts')) as RouterHts__factory;
    const routerHts = await RouterHts.deploy(coreHts.address, precompileHts.address, deployOverrides);
    await routerHts.deployed();

    const SuperRouter = (await ethers.getContractFactory('SuperRouter')) as SuperRouterHts__factory;
    const superRouter = await SuperRouter.deploy(routerHts.address, precompileHts.address, deployOverrides);
    await superRouter.deployed();

    console.log('-- core.address:', coreHts.address);
    console.log('-- precompile.address:', precompileHts.address);
    console.log('-- router.address:', routerHts.address);

    // const routeTx = await router.route();
    const routeTx = await routerHts.normalRoute();

    console.log('-- done router.normalRoute() --');

    const superRouteTx = await superRouter.routeViaRouter();

    console.log('-- done superRouter.routeViaRouter() --');

  });
});
