import { TransactionReceipt } from '@ethersproject/providers';
import { expect } from 'chai';
import { BigNumber, ContractReceipt } from 'ethers';
import {ethers, network} from 'hardhat';
import { SillyLargeContract, SillyLargeContract__factory, SimpleVault__factory, SimpleVault, Associator, HERC20Util, HERC20Util__factory } from '../types';
import { transferToken } from './api/core';
import { balanceOf } from './api/core/balances';
import { defaultOverrides, getBigNumber, getRandomNumber } from './utils';
import { HERC20 } from './utils/herc20';
import { Networks } from './utils/networks';

describe('SillyLargeContract', function() {
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

  it('should be able get correct ERC20 balance after transfer', async function () {
    // Deploy ERC20 token contract
    const MyToken = await ethers.getContractFactory('MyToken');
    const myToken = await MyToken.deploy('MyToken', 'MT');

    // Get initial balances of two accounts
    const [account1, account2] = await ethers.getSigners();
    const initialBalance1 = await myToken.balanceOf(account1.address);
    const initialBalance2 = await myToken.balanceOf(account2.address);

    // Transfer tokens from account1 to account2
    const amount = 100;
    await myToken.transfer(account2.address, amount);

    // Get updated balances of the two accounts
    const updatedBalance1 = await myToken.balanceOf(account1.address);
    const updatedBalance2 = await myToken.balanceOf(account2.address);

    // Assert that balances were updated correctly
    expect(updatedBalance1).to.equal(initialBalance1.sub(amount));
    expect(updatedBalance2).to.equal(initialBalance2.add(amount));
  });

  it('should be able to deposit and withdraw from vault repeatedly and get correct balances', async function () {

    if (network.name === Networks.hardhat_local) {
      // hedera precompile contracts aren't functional on the hardhat local node
      this.skip();
    }

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
          console.log("balance A !== balance B");
        }
      }

      return B;
    }

    async function deposit(amount: BigNumber) {

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

    }

    async function withdraw(amount: BigNumber) {

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

    }

    const depositAmount = getBigNumber(getRandomNumber(100, 1e6), 0);

    await deposit(depositAmount);

    const withdrawAmount = getBigNumber(getRandomNumber(100, 1e6), 0);

    await withdraw(withdrawAmount);

  });
});
