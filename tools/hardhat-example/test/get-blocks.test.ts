import { expect } from 'chai';
import { Block } from '@ethersproject/providers';
import { ethers } from 'hardhat';
import {
  PromiseStatus
} from './utils'

describe('Get blocks in parallel', function () {
  const startBlock = 522_928;
  const endBlock = 523_100;
  const testCases = [10, 100, 1_000]; // block ranges

  async function getParallelBlocks(startBlock: number, endBlock: number, blockRange: number) {

    for (let i = startBlock; i < endBlock; i += blockRange) {

      const promises = [];
      const upper = Math.min(i + blockRange, endBlock);
      for (let j = i; j < upper; j++) {
        promises.push(
          ethers.provider.getBlock(j)
        );
      }

      // wait for all promises to settle before proceeding onto getting next block range
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

    }
  }

  for (const testCase of testCases) {
    it(`gets ${testCase} blocks in parallel`, async () => {
      await getParallelBlocks(startBlock, endBlock, testCase);
    });
  }
});
