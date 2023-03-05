import { expect } from 'chai';
import {ethers} from 'hardhat';
import { SillyLargeContract, SillyLargeContract__factory } from '../types';

describe('SillyLargeContract', function() {
  const parallelDeployCount = 2;
  const parallelCallCount = 4;

  let sillyLargeContract: SillyLargeContract;
  let SillyLargeContractFactory: SillyLargeContract__factory;

  before(async () => {
    SillyLargeContractFactory = await ethers.getContractFactory("SillyLargeContract");

    sillyLargeContract = (await SillyLargeContractFactory.deploy()) as SillyLargeContract;
    await sillyLargeContract.deployed();
  });

  it('should be able to deploy many SillyLargeContract in parallel', async function() {
    const deployments = [];
    for (let i = 0; i < parallelDeployCount; i++) {
      deployments.push(SillyLargeContractFactory.deploy());
    }
    const contracts = await Promise.all(deployments);
    expect(contracts.length).to.equal(parallelDeployCount);
  });

  it('should be able to call setManyGreetings function in parallel', async function() {
    const commonGreeting = "hello world";
    const calls = [];
    for (let i = 0; i < parallelCallCount; i++) {
      calls.push(sillyLargeContract.setManyGreetings(commonGreeting));
    }
    await Promise.all(calls);
  });

  it('should be able to call setManyGreetings function in parallel with gas overrides', async function() {
    const commonGreeting = "hello world";
    const calls = [];
    for (let i = 0; i < parallelCallCount; i++) {
      calls.push(sillyLargeContract.setManyGreetings(commonGreeting, {
        gasLimit: 1_000_000
      }));
    }
    await Promise.all(calls);
  });
});
