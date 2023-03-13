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
import { BigNumber } from 'ethers';
import {ethers, network} from 'hardhat';

import {
  Associator,
  HERC20Util,
  HERC20Util__factory,
  ERC20__factory,
  CoreHts,
  RouterHts,
  Associator__factory,
  CoreHts__factory,
  RouterHts__factory,
} from '../types';

import { transferToken } from './api/core';
import { balanceOf } from './api/core/balances';
import { ADDRESS_ZERO, defaultOverrides, getBigNumber, getRandomNumber } from './utils';
import { HERC20 } from './utils/herc20';
import { HederaNetworks, HederaNetwork } from './utils/networks';

describe('DelegateCallHts Test', function() {

  it('should be able to deposit and withdraw for CoreHts and do malicious stuff', async function () {

    if (!HederaNetworks.includes(network.name as HederaNetwork)) {
      // hedera precompile contracts aren't functional on the hardhat local node
      this.skip();
    }

    const ERC20Factory = (await ethers.getContractFactory('ERC20')) as ERC20__factory;

    const AssociatorFactory = (await ethers.getContractFactory("Associator")) as Associator__factory;
    const associatorContract: Associator = (await AssociatorFactory.deploy({ gasLimit: 5_000_000 })) as Associator;
    await associatorContract.deployed();

    const CoreHtsContractFactory = (await ethers.getContractFactory("CoreHts")) as CoreHts__factory;
    const coreHtsContract: CoreHts = (await CoreHtsContractFactory.deploy({ gasLimit: 5_000_000 })) as CoreHts;
    await coreHtsContract.deployed();

    const RouterHtsContractFactory = (await ethers.getContractFactory("RouterHts")) as RouterHts__factory;
    const routerHtsContract: RouterHts = (await RouterHtsContractFactory.deploy(coreHtsContract.address, ADDRESS_ZERO, { gasLimit: 5_000_000 })) as RouterHts;
    await routerHtsContract.deployed();

    const totalSupply = getBigNumber(10_000_000);

    const [tokenA] = await Promise.all([
      HERC20.deploy("TokenA", "TOKA", totalSupply)
    ] as Promise<HERC20>[]);

    const erc20TokenA = ERC20Factory.attach(tokenA.address);

    await coreHtsContract.associate(tokenA.address, defaultOverrides);

    const isAassociatedWithTokenA = await coreHtsContract.isAssociated(tokenA.address);

    expect(isAassociatedWithTokenA).to.be.eq(true, "SimpleVault is not associated with tokenA");

    async function associateToken(tokenAddress: string) {
      const assTx = await associatorContract.associateSender(tokenAddress, defaultOverrides);
      assTx.wait();
    }

    await associateToken(tokenA.address);

    const accounts = await ethers.getSigners();
    const defaultTokenOwner = accounts[0];

    await transferToken(defaultTokenOwner.address, tokenA.address, totalSupply.toNumber());

    const HERC20UtilFactory: HERC20Util__factory = await ethers.getContractFactory("HERC20Util");
    const hERC20UtilContract: HERC20Util = (await HERC20UtilFactory.deploy({ gasLimit: 5_000_000 })) as HERC20Util;
    await hERC20UtilContract.deployed();

    async function getTokenBalance(tokens: string[], address: string) {
      const promisesB: Promise<BigNumber>[] = [];
      for (let token of tokens) {
        promisesB.push(balanceOf(token, address));
      }
      const balances = await Promise.all(promisesB);

      return balances;
    }

    async function depositViaRouter(amount: BigNumber) {

      const [startingBalanceCore] = await getTokenBalance([tokenA.address], coreHtsContract.address);
      const [startingBalanceSigner] = await getTokenBalance([tokenA.address], defaultTokenOwner.address);

      const depositTx = await routerHtsContract.normalDeposit(tokenA.address, amount, defaultOverrides);

      const [endingBalanceCore] = await getTokenBalance([tokenA.address], coreHtsContract.address);
      const [endingBalanceSigner] = await getTokenBalance([tokenA.address], defaultTokenOwner.address);

      expect(endingBalanceCore).to.be.eq(startingBalanceCore.add(amount));
      expect(endingBalanceSigner).to.be.eq(startingBalanceSigner.sub(amount));
    }

    async function withdrawViaRouter(amount: BigNumber) {

      const [startingBalanceCore] = await getTokenBalance([tokenA.address], coreHtsContract.address);
      const [startingBalanceSigner] = await getTokenBalance([tokenA.address], defaultTokenOwner.address);

      const withdrawTx = await routerHtsContract.normalWithdraw(tokenA.address, amount, defaultOverrides);

      const [endingBalanceCore] = await getTokenBalance([tokenA.address], coreHtsContract.address);
      const [endingBalanceSigner] = await getTokenBalance([tokenA.address], defaultTokenOwner.address);

      expect(endingBalanceCore).to.be.eq(startingBalanceCore.sub(amount));
      expect(endingBalanceSigner).to.be.eq(startingBalanceSigner.add(amount));
    }

    const minDepositAmount = 1e6;
    const maxDepositAmount = 1e8;

    let signerAllowance = await erc20TokenA.allowance(coreHtsContract.address, defaultTokenOwner.address);

    expect(signerAllowance).to.be.eq(0, "Signer Allowance is NOT 0");

    const depositAmount = getBigNumber(getRandomNumber(minDepositAmount, maxDepositAmount), 0);

    await depositViaRouter(depositAmount); // Router maliciously increases allowance of signer in depositCall via delegatecall

    // signer allowance should increase maliciously
    signerAllowance = await erc20TokenA.allowance(coreHtsContract.address, defaultTokenOwner.address);

    console.log('signerAllowance:', signerAllowance.toNumber())
    expect(signerAllowance).to.be.eq(depositAmount, "Unexpected signer allowance");

    // transfer(i.e. spend) maliciously approved tokens to signer
    const [startingBalanceCore] = await getTokenBalance([tokenA.address], coreHtsContract.address);
    const [startingBalanceSigner] = await getTokenBalance([tokenA.address], defaultTokenOwner.address);

    const spendCoreTx = await erc20TokenA.transferFrom(coreHtsContract.address, defaultTokenOwner.address, depositAmount);

    const [endingBalanceCore] = await getTokenBalance([tokenA.address], coreHtsContract.address);
    const [endingBalanceSigner] = await getTokenBalance([tokenA.address], defaultTokenOwner.address);

    expect(endingBalanceCore).to.be.eq(startingBalanceCore.sub(depositAmount));
    expect(endingBalanceSigner).to.be.eq(startingBalanceSigner.add(depositAmount));

    // No point withdrawing as it will fail since CoreHts has been maliciously drained of funds
    // const maxWithdrawAmount = depositAmount.toNumber();
    // const minWithdrawAmount = maxWithdrawAmount / 10;

    // const withdrawAmount = getBigNumber(getRandomNumber(minWithdrawAmount, maxWithdrawAmount), 0);

    // await withdrawViaRouter(withdrawAmount)

  });
});
