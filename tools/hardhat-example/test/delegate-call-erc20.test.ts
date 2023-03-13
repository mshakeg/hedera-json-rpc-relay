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
import { ethers } from 'hardhat';

import {
  ERC20__factory,
  CoreERC20,
  RouterERC20,
  CoreERC20__factory,
  RouterERC20__factory,
  DollarToken__factory,
  DollarToken
} from '../types';

import { ADDRESS_ZERO, defaultOverrides, getBigNumber, getRandomNumber } from './utils';

describe('DelegateCallERC20 Test', function () {

  it('should be able to deposit and withdraw for CoreERC20 and do malicious stuff', async function () {

    const DollarTokenFactory = (await ethers.getContractFactory('DollarToken')) as DollarToken__factory;

    const ERC20Factory = (await ethers.getContractFactory('ERC20')) as ERC20__factory;

    const totalSupply = getBigNumber(10_000_000);

    const dollarTokenContract: DollarToken = (await DollarTokenFactory.deploy(totalSupply, { gasLimit: 5_000_000 })) as DollarToken;
    await dollarTokenContract.deployed();

    const tokenA = dollarTokenContract;

    const CoreERC20ContractFactory = (await ethers.getContractFactory("CoreERC20")) as CoreERC20__factory;
    const coreERC20Contract: CoreERC20 = (await CoreERC20ContractFactory.deploy({ gasLimit: 5_000_000 })) as CoreERC20;
    await coreERC20Contract.deployed();

    const RouterERC20ContractFactory = (await ethers.getContractFactory("RouterERC20")) as RouterERC20__factory;
    const routerERC20Contract: RouterERC20 = (await RouterERC20ContractFactory.deploy(coreERC20Contract.address, ADDRESS_ZERO, { gasLimit: 5_000_000 })) as RouterERC20;
    await routerERC20Contract.deployed();

    const accounts = await ethers.getSigners();
    const defaultTokenOwner = accounts[0];

    async function getTokenBalance(tokens: string[], address: string) {
      const promisesB: Promise<BigNumber>[] = [];
      for (let token of tokens) {
        const erc20Token = ERC20Factory.attach(token);
        promisesB.push(erc20Token.balanceOf(address));
      }
      const balances = await Promise.all(promisesB);
      return balances;
    }

    async function depositViaRouter(amount: BigNumber, isMalicious: boolean = false) {

      const [startingBalanceCore] = await getTokenBalance([tokenA.address], coreERC20Contract.address);
      const [startingBalanceSigner] = await getTokenBalance([tokenA.address], defaultTokenOwner.address);

      if (isMalicious) {
        const depositTx = await routerERC20Contract.maliciousDeposit(tokenA.address, amount, defaultOverrides);
      } else {
        const depositTx = await routerERC20Contract.normalDeposit(tokenA.address, amount, defaultOverrides);
      }

      const [endingBalanceCore] = await getTokenBalance([tokenA.address], coreERC20Contract.address);
      const [endingBalanceSigner] = await getTokenBalance([tokenA.address], defaultTokenOwner.address);

      expect(endingBalanceCore).to.be.eq(startingBalanceCore.add(amount));
      expect(endingBalanceSigner).to.be.eq(startingBalanceSigner.sub(amount));
    }

    async function withdrawViaRouter(amount: BigNumber) {

      const [startingBalanceCore] = await getTokenBalance([tokenA.address], coreERC20Contract.address);
      const [startingBalanceSigner] = await getTokenBalance([tokenA.address], defaultTokenOwner.address);

      const withdrawTx = await routerERC20Contract.normalWithdraw(tokenA.address, amount, defaultOverrides);

      const [endingBalanceCore] = await getTokenBalance([tokenA.address], coreERC20Contract.address);
      const [endingBalanceSigner] = await getTokenBalance([tokenA.address], defaultTokenOwner.address);

      expect(endingBalanceCore).to.be.eq(startingBalanceCore.sub(amount));
      expect(endingBalanceSigner).to.be.eq(startingBalanceSigner.add(amount));
    }

    console.log('-- defaultTokenOwner.address:', defaultTokenOwner.address);
    console.log('-- core.address:', coreERC20Contract.address);
    console.log('-- router.address:', routerERC20Contract.address);
    console.log('-- dollarToken.address:', dollarTokenContract.address);

    const minDepositAmount = 1e6;
    const maxDepositAmount = 1e8;

    let signerAllowance = await dollarTokenContract.allowance(coreERC20Contract.address, defaultTokenOwner.address);

    expect(signerAllowance).to.be.eq(0, "Signer Allowance is NOT 0");

    const depositAmount = getBigNumber(getRandomNumber(minDepositAmount, maxDepositAmount), 0);

    const approveRouterTx = await dollarTokenContract.approve(routerERC20Contract.address, depositAmount);

    const isMalicious = true;

    await depositViaRouter(depositAmount, isMalicious);

    if (isMalicious) {

      // malicious attempts at increasing the allowance fails since delegatecall modifies the storage of the Caller and not the Called ERC20 contract
      signerAllowance = await dollarTokenContract.allowance(coreERC20Contract.address, defaultTokenOwner.address);
      expect(signerAllowance).to.be.eq(0, "Signer allowance should be 0");

    } else {
      // No point withdrawing as it will fail since CoreHts has been maliciously drained of funds
      const maxWithdrawAmount = depositAmount.toNumber();
      const minWithdrawAmount = maxWithdrawAmount / 10;

      const withdrawAmount = getBigNumber(getRandomNumber(minWithdrawAmount, maxWithdrawAmount), 0);

      await withdrawViaRouter(withdrawAmount)
    }

  });
});
