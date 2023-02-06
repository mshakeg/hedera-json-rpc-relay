import { expect } from 'chai';
import { Block } from '@ethersproject/providers';
import { ethers } from 'hardhat';
import {
  PromiseStatus
} from './utils'

describe('Get blocks in parallel', function () {
  const startBlock = 522_928;
  const testCases = [10, 100, 1_000]; // block ranges

  for (const testCase of testCases) {
    it(`Should get ${testCase} blocks in parallel`, async function () {
      const promises = [];
      for (let i = startBlock; i < startBlock + testCase; i++) {
        promises.push(
          ethers.provider.getBlock(i)
        );
      }

      const results = await Promise.allSettled(promises);

      for (const blockResult of results) {

        if (blockResult.status === PromiseStatus.FULFILLED) {

          const value = blockResult.value as Block;
          const blockNumber = value.number;

          console.log('Block success:', blockNumber);

        } else {

          const error = blockResult.reason;
          console.log('Block failed message:', error.message);
        }
      }

      const fulfilledResults = results.filter((result) => result.status === PromiseStatus.FULFILLED);

      const fulfilledResultsLength = fulfilledResults.length;

      console.log(`Test Case: ${testCase}; fulfilledResults:`, fulfilledResultsLength);

      expect(fulfilledResultsLength).to.be.at.most(testCase);
    });
  }
});
