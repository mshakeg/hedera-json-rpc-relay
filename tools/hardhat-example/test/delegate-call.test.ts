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
  Router__factory,
  Precompile__factory,
  SuperRouter__factory
} from '../types';

import {
  deployOverrides
} from './utils';

describe('DelegateCall Test', function() {

  it('show logs', async function() {
    const Core = await ethers.getContractFactory('Core');
    const core = await Core.deploy(deployOverrides);
    await core.deployed();

    const Precompile = (await ethers.getContractFactory('Precompile')) as Precompile__factory;
    const precompile = await Precompile.deploy(deployOverrides);
    await precompile.deployed();

    const Router = (await ethers.getContractFactory('Router')) as Router__factory;
    const router = await Router.deploy(core.address, precompile.address, deployOverrides);
    await router.deployed();

    const SuperRouter = (await ethers.getContractFactory('SuperRouter')) as SuperRouter__factory;
    const superRouter = await SuperRouter.deploy(router.address, precompile.address, deployOverrides);
    await superRouter.deployed();

    console.log('-- core.address:', core.address);
    console.log('-- precompile.address:', precompile.address);
    console.log('-- router.address:', router.address);

    // const routeTx = await router.route();
    const routeTx = await router.normalRoute();

    console.log('-- done router.normalRoute() --');

    const superRouteTx = await superRouter.routeViaRouter();

    console.log('-- done superRouter.routeViaRouter() --');

  });
});
