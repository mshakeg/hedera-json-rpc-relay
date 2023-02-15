import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';

import {
  PromiseStatus,
  removeLeadingZeros
} from './utils'

describe('Get block transactions in parallel', function () {
  const startBlock = 522_900;
  const endBlock = 523_900;
  const testCases = [10]; // block ranges , 100, 1_000

  async function getParallelBlockTransactionsCount(startBlock: number, endBlock: number, blockRange: number) {

    let blockNumber;

    for (let i = startBlock; i < endBlock; i += blockRange) {

      const promises: Array<Promise<string>> = [];
      const upper = Math.min(i + blockRange, endBlock);

      console.log(`getting block txs count range: [${i}, ${upper}]`);

      for (let j = i; j < upper; j++) {

        blockNumber = removeLeadingZeros(j);

        promises.push(
          ethers.provider.send('eth_getBlockTransactionCountByNumber', [blockNumber, false])
        );
      }

      // wait for all promises to settle before proceeding onto getting next block range
      const results = await Promise.allSettled(promises);

      for (const blockResult of results) {

        if (blockResult.status === PromiseStatus.FULFILLED) {

          const blockTxCount = BigNumber.from(blockResult.value);

          console.log('Block success:', blockTxCount.toNumber());

        } else {

          const error = blockResult.reason;
          console.log('Block failed message:', error.message);
        }
      }

    }
  }

  for (const testCase of testCases) {
    it(`gets ${testCase} blocks in parallel`, async () => {
      await getParallelBlockTransactionsCount(startBlock, endBlock, testCase);
    });
  }
});
