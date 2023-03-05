import { TransactionReceipt } from '@ethersproject/providers';
import { expect } from 'chai';
import { ContractReceipt } from 'ethers';
import {ethers} from 'hardhat';
import { SillyLargeContract, SillyLargeContract__factory } from '../types';

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
  });
});
