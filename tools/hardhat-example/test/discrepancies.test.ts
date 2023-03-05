import { TransactionReceipt } from '@ethersproject/providers';
import { expect } from 'chai';
import { BigNumber, ContractReceipt } from 'ethers';
import {ethers, network} from 'hardhat';
import { SillyLargeContract, SillyLargeContract__factory, SimpleVault__factory, SimpleVault, Associator, HERC20Util, HERC20Util__factory, ERC20__factory } from '../types';
import { transferToken } from './api/core';
import { balanceOf } from './api/core/balances';
import { defaultOverrides, getBigNumber, getRandomNumber } from './utils';
import { HERC20 } from './utils/herc20';
import { Networks } from './utils/networks';

describe('Demo discrepancies between hardhat and hedera local node', function() {
  const parallelDeployCount = 2;
  const parallelCallCount = 2;

  let sillyLargeContract: SillyLargeContract;
  let SillyLargeContractFactory: SillyLargeContract__factory;

  before(async () => {
    try {
      SillyLargeContractFactory = await ethers.getContractFactory("SillyLargeContract");
      sillyLargeContract = (await SillyLargeContractFactory.deploy()) as SillyLargeContract;
      await sillyLargeContract.deployed();
    } catch (e) {
      console.log('ERROR: initial sillyLargeContract deploy fails on the hedera local node as gas override is not set');
      sillyLargeContract = (await SillyLargeContractFactory.deploy({ gasLimit: 2_000_000 })) as SillyLargeContract;
      await sillyLargeContract.deployed();
    }
  });

  it('should be able to deploy many SillyLargeContract in parallel', async function() {
    const deployments = [];
    for (let i = 0; i < parallelDeployCount; i++) {
      deployments.push(SillyLargeContractFactory.deploy());
    }
    const contracts = await Promise.all(deployments);

    const deployPromises: Array<Promise<TransactionReceipt>> = [];
    for (let contract of contracts) {
      deployPromises.push(contract.deployTransaction.wait());
    }

    const deployedContracts = await Promise.all(deployPromises);

    for (let contract of deployedContracts) {
      console.log(contract.contractAddress)
    }

    expect(contracts.length).to.equal(parallelDeployCount);
    expect(deployedContracts[0].contractAddress).to.not.eq(deployedContracts[1].contractAddress, "contracts have same addresses");
  });

  it('should be able to deploy many SillyLargeContract in parallel with gas overrides', async function() {
    const deployments = [];
    for (let i = 0; i < parallelDeployCount; i++) {
      deployments.push(SillyLargeContractFactory.deploy({ gasLimit: 5_000_000 }));
    }
    const contracts = await Promise.all(deployments);

    const deployPromises: Array<Promise<TransactionReceipt>> = [];
    for (let contract of contracts) {
      deployPromises.push(contract.deployTransaction.wait());
    }

    const deployedContracts = await Promise.all(deployPromises);

    for (let contract of deployedContracts) {
      console.log(contract.contractAddress)
    }

    expect(contracts.length).to.equal(parallelDeployCount);
    expect(deployedContracts[0].contractAddress).to.not.eq(deployedContracts[1].contractAddress, "contracts have same addresses");
  });

  it('should be able to call setManyGreetings function in parallel', async function() {
    const commonGreeting = "hello world";
    const calls = [];
    for (let i = 0; i < parallelCallCount; i++) {
      calls.push(sillyLargeContract.setManyGreetings(commonGreeting));
    }
    const txs = await Promise.all(calls);

    const rcsPromises: Array<Promise<ContractReceipt>> = [];

    for (let tx of txs) {
      rcsPromises.push(tx.wait());
    }

    const rcs = await Promise.all(rcsPromises);

    for (const rc of rcs) {
      console.log(rc.transactionHash);
    }

    expect(rcs[0].transactionHash).to.not.eq(rcs[1].transactionHash, "txs have same hashes");
  });

  it('should be able to call setManyGreetings function in parallel with gas overrides', async function() {
    const commonGreeting = "hello world";
    const calls = [];
    for (let i = 0; i < parallelCallCount; i++) {
      calls.push(sillyLargeContract.setManyGreetings(commonGreeting, {
        gasLimit: 2_000_000
      }));
    }
    const txs = await Promise.all(calls);

    const rcsPromises: Array<Promise<ContractReceipt>> = [];

    for (let tx of txs) {
      rcsPromises.push(tx.wait());
    }

    const rcs = await Promise.all(rcsPromises);

    for (const rc of rcs) {
      console.log(rc.transactionHash);
    }

    expect(rcs[0].transactionHash).to.not.eq(rcs[1].transactionHash, "txs have same hashes");
  });



  it('should be able to deposit and withdraw from vault repeatedly and get correct balances', async function () {

    if (network.name === Networks.hardhat_local) {
      // hedera precompile contracts aren't functional on the hardhat local node
      this.skip();
    }

    const ERC20Factory = (await ethers.getContractFactory('ERC20')) as ERC20__factory;

    const AssociatorFactory = await ethers.getContractFactory("Associator");
    const associatorContract: Associator = (await AssociatorFactory.deploy({ gasLimit: 5_000_000 })) as Associator;
    await associatorContract.deployed();

    const SimpleVaultFactory = await ethers.getContractFactory("SimpleVault");
    const simpleVaultContract: SimpleVault = (await SimpleVaultFactory.deploy({ gasLimit: 5_000_000 })) as SimpleVault;
    await simpleVaultContract.deployed();

    const totalSupply = getBigNumber(10_000_000)

    const [tokenA, tokenB] = await Promise.all([
      HERC20.deploy("TokenA", "TOKA", totalSupply),
      HERC20.deploy("TokenB", "TOKB", totalSupply),
    ] as Promise<HERC20>[]);

    const erc20TokenA = ERC20Factory.attach(tokenA.address);
    const erc20TokenB = ERC20Factory.attach(tokenB.address);

    await simpleVaultContract.associate(tokenA.address, defaultOverrides);
    await simpleVaultContract.associate(tokenB.address, defaultOverrides);

    const isAassociatedWithTokenA = await simpleVaultContract.isAssociated(tokenA.address);
    const isAassociatedWithTokenB = await simpleVaultContract.isAssociated(tokenB.address);

    expect(isAassociatedWithTokenA).to.be.eq(true, "SimpleVault is not associated with tokenA");
    expect(isAassociatedWithTokenB).to.be.eq(true, "SimpleVault is not associated with tokenB");

    async function associateToken(tokenAddress: string) {
      const assTx = await associatorContract.associateSender(tokenAddress, defaultOverrides);
      assTx.wait();
    }

    await associateToken(tokenA.address);
    await associateToken(tokenB.address);

    const accounts = await ethers.getSigners();
    const defaultTokenOwner = accounts[0];

    await transferToken(defaultTokenOwner.address, tokenA.address, totalSupply.toNumber());
    await transferToken(defaultTokenOwner.address, tokenB.address, totalSupply.toNumber());

    const HERC20UtilFactory: HERC20Util__factory = await ethers.getContractFactory("HERC20Util");
    const hERC20UtilContract: HERC20Util = (await HERC20UtilFactory.deploy({ gasLimit: 5_000_000 })) as HERC20Util;
    await hERC20UtilContract.deployed();

    async function getTokenBalances(address: string): Promise<Array<BigNumber>> {
      const balanceTokenA = erc20TokenA.balanceOf(address);
      const balanceTokenB = erc20TokenB.balanceOf(address);

      return Promise.all([
        balanceTokenA,
        balanceTokenB
      ]);
    }

    async function getTokenBalance(tokens: string[], address: string) {
      const promisesA: Promise<BigNumber>[] = [];
      const promisesB: Promise<BigNumber>[] = [];
      for (let token of tokens) {
        promisesA.push(hERC20UtilContract.balanceOf(token, address));
        promisesB.push(balanceOf(token, address));
      }
      const A = await Promise.all(promisesA);
      const B = await Promise.all(promisesB);

      for (let index in A) {
        const balanceA = A[index];
        const balanceB = B[index];

        // for some reason the balance returned by the HERC20Util is not correct; but the balance returned via the @hashgraph/sdk is correct; hence why B and NOT A is returned
        if (!balanceA.eq(balanceB)) {
          console.log("balance Core !== balance HERC20Util");
        }
      }

      return B;
    }

    async function deposit(amount: BigNumber): Promise<{endingBalanceSigner: BigNumber}> {

      const [startingBalanceVaultA, startingBalanceVaultB] = await getTokenBalance([tokenA.address, tokenB.address], simpleVaultContract.address);
      const [startingBalanceSignerA, startingBalanceSignerB] = await getTokenBalance([tokenA.address, tokenB.address], defaultTokenOwner.address);

      const depositATx = await simpleVaultContract.deposit(tokenA.address, amount, defaultOverrides);
      const depositBTx = await simpleVaultContract.deposit(tokenB.address, amount, defaultOverrides);

      const [endingBalanceVaultA, endingBalanceVaultB] = await getTokenBalance([tokenA.address, tokenB.address], simpleVaultContract.address);
      const [endingBalanceSignerA, endingBalanceSignerB] = await getTokenBalance([tokenA.address, tokenB.address], defaultTokenOwner.address);

      expect(endingBalanceVaultA).to.be.eq(startingBalanceVaultA.add(amount));
      expect(endingBalanceVaultB).to.be.eq(startingBalanceVaultB.add(amount));

      expect(endingBalanceSignerA).to.be.eq(startingBalanceSignerA.sub(amount));
      expect(endingBalanceSignerB).to.be.eq(startingBalanceSignerB.sub(amount));

      const signerVaultBalanceA = await simpleVaultContract.vaultBalances(tokenA.address, defaultTokenOwner.address);

      return {
        endingBalanceSigner: signerVaultBalanceA,
      };
    }

    async function withdraw(amount: BigNumber): Promise<{endingBalanceSigner: BigNumber}> {

      const [startingBalanceVaultA, startingBalanceVaultB] = await getTokenBalance([tokenA.address, tokenB.address], simpleVaultContract.address);
      const [startingBalanceSignerA, startingBalanceSignerB] = await getTokenBalance([tokenA.address, tokenB.address], defaultTokenOwner.address);

      const withdrawATx = await simpleVaultContract.withdraw(tokenA.address, amount, defaultOverrides);
      const withdrawBTx = await simpleVaultContract.withdraw(tokenB.address, amount, defaultOverrides);

      const [endingBalanceVaultA, endingBalanceVaultB] = await getTokenBalance([tokenA.address, tokenB.address], simpleVaultContract.address);
      const [endingBalanceSignerA, endingBalanceSignerB] = await getTokenBalance([tokenA.address, tokenB.address], defaultTokenOwner.address);

      expect(endingBalanceVaultA).to.be.eq(startingBalanceVaultA.sub(amount));
      expect(endingBalanceVaultB).to.be.eq(startingBalanceVaultB.sub(amount));

      expect(endingBalanceSignerA).to.be.eq(startingBalanceSignerA.add(amount));
      expect(endingBalanceSignerB).to.be.eq(startingBalanceSignerB.add(amount));

      const signerVaultBalanceA = await simpleVaultContract.vaultBalances(tokenA.address, defaultTokenOwner.address);

      return {
        endingBalanceSigner: signerVaultBalanceA,
      };

    }

    async function depositAndWithdraw(shouldDepositA: boolean, depositAmount: BigNumber, withdrawAmount: BigNumber): Promise<{signerBalanceVaultA: BigNumber, signerBalanceVaultB: BigNumber}> {

      const [startingBalanceVaultA, startingBalanceVaultB] = await getTokenBalance([tokenA.address, tokenB.address], simpleVaultContract.address);
      const [startingBalanceSignerA, startingBalanceSignerB] = await getTokenBalance([tokenA.address, tokenB.address], defaultTokenOwner.address);

      const [startingERC20BalanceVaultA, startingERC20BalanceVaultB] = await getTokenBalances(simpleVaultContract.address);
      const [startingERC20BalanceSignerA, startingERC20BalanceSignerB] = await getTokenBalances(defaultTokenOwner.address);

      if (!startingERC20BalanceVaultA.eq(startingBalanceVaultA)) {
        console.log('1 - balance Core !== balance ERC20');
      }

      if (!startingERC20BalanceVaultB.eq(startingBalanceVaultB)) {
        console.log('2 - balance Core !== balance ERC20');
      }

      if (!startingERC20BalanceSignerA.eq(startingBalanceSignerA)) {
        console.log('3 - balance Core !== balance ERC20');
      }

      if (!startingERC20BalanceSignerB.eq(startingBalanceSignerB)) {
        console.log('4 - balance Core !== balance ERC20');
      }

      if (shouldDepositA) {
        const depositAndWithdrawTx = await simpleVaultContract.depositAndWithdraw(tokenA.address, depositAmount, tokenB.address, withdrawAmount, defaultOverrides);
      } else {
        const depositAndWithdrawTx = await simpleVaultContract.depositAndWithdraw(tokenB.address, depositAmount, tokenA.address, withdrawAmount, defaultOverrides);
      }

      const [endingBalanceVaultA, endingBalanceVaultB] = await getTokenBalance([tokenA.address, tokenB.address], simpleVaultContract.address);
      const [endingBalanceSignerA, endingBalanceSignerB] = await getTokenBalance([tokenA.address, tokenB.address], defaultTokenOwner.address);

      const [endingERC20BalanceVaultA, endingERC20BalanceVaultB] = await getTokenBalances(simpleVaultContract.address);
      const [endingERC20BalanceSignerA, endingERC20BalanceSignerB] = await getTokenBalances(defaultTokenOwner.address);

      if (!endingERC20BalanceVaultA.eq(endingBalanceVaultA)) {
        console.log('5 - balance Core !== balance ERC20');
      }

      if (!endingERC20BalanceVaultB.eq(endingBalanceVaultB)) {
        console.log('6 - balance Core !== balance ERC20');
      }

      if (!endingERC20BalanceSignerA.eq(endingBalanceSignerA)) {
        console.log('7 - balance Core !== balance ERC20');
      }

      if (!endingERC20BalanceSignerB.eq(endingBalanceSignerB)) {
        console.log('8 - balance Core !== balance ERC20');
      }

      if (shouldDepositA) {
        expect(endingBalanceVaultA).to.be.eq(startingBalanceVaultA.add(depositAmount));
        expect(endingBalanceVaultB).to.be.eq(startingBalanceVaultB.sub(withdrawAmount));

        expect(endingBalanceSignerA).to.be.eq(startingBalanceSignerA.sub(depositAmount));
        expect(endingBalanceSignerB).to.be.eq(startingBalanceSignerB.add(withdrawAmount));
      } else { // deposit B
        expect(endingBalanceVaultB).to.be.eq(startingBalanceVaultB.add(depositAmount));
        expect(endingBalanceVaultA).to.be.eq(startingBalanceVaultA.sub(withdrawAmount));

        expect(endingBalanceSignerB).to.be.eq(startingBalanceSignerB.sub(depositAmount));
        expect(endingBalanceSignerA).to.be.eq(startingBalanceSignerA.add(withdrawAmount));
      }

      const signerVaultBalanceA = await simpleVaultContract.vaultBalances(tokenA.address, defaultTokenOwner.address);
      const signerVaultBalanceB = await simpleVaultContract.vaultBalances(tokenB.address, defaultTokenOwner.address);

      return {
        signerBalanceVaultA: signerVaultBalanceA,
        signerBalanceVaultB: signerVaultBalanceB
      };
    }

    // Does consistently get balances correctly using both SDK and HERC20Util for withdraw() and deposit() calls
    const iterations = 5;

    let maxAmount = 1e6;

    for (let i = 0; i < iterations; i++) {

      console.log('simple iter:', i);

      const depositAmount = getBigNumber(getRandomNumber(1, maxAmount), 0);
      const { endingBalanceSigner: endingBalanceSignerDeposit } = await deposit(depositAmount);
      maxAmount = endingBalanceSignerDeposit.toNumber();

      const withdrawAmount = getBigNumber(getRandomNumber(1, maxAmount), 0);
      const { endingBalanceSigner: endingBalanceSignerWithdraw } = await withdraw(withdrawAmount);
      maxAmount = endingBalanceSignerWithdraw.toNumber();

    }

    // Does NOT consistently get balances correctly using both SDK and HERC20Util when using depositAndWithdraw()
    let maxDepositAmount = 1e6;
    let maxWithdrawAmount = 0; // initially no funds to withdraw

    for (let i = 0; i < iterations; i++) {

      console.log('depositAndWithdraw iter:', i);

      const minDepositAmount = Math.floor(maxDepositAmount/2);

      let depositAmount = getBigNumber(getRandomNumber(minDepositAmount, maxDepositAmount), 0);
      let withdrawAmount = maxWithdrawAmount ? getBigNumber(getRandomNumber(1, maxWithdrawAmount), 0) : BigNumber.from(0);

      const {signerBalanceVaultA: _signerBalanceVaultA1, signerBalanceVaultB: _signerBalanceVaultB1} = await depositAndWithdraw(true, depositAmount, withdrawAmount);

      maxWithdrawAmount = _signerBalanceVaultA1.toNumber();
      const minWithdrawAmount = Math.floor(maxWithdrawAmount/2);

      withdrawAmount = getBigNumber(getRandomNumber(minWithdrawAmount, maxWithdrawAmount), 0);
      const {signerBalanceVaultA: _signerBalanceVaultA2, signerBalanceVaultB: _signerBalanceVaultB2} = await depositAndWithdraw(false, depositAmount, withdrawAmount);

      maxDepositAmount = _signerBalanceVaultA2.toNumber();
      maxWithdrawAmount = _signerBalanceVaultB2.toNumber()

    }
  });
});
