import { expect } from "chai";
import { ethers } from 'hardhat';

import {
  SimpleCounter
} from "../types";

import {
  sleep
} from './utils';

describe("SimpleCounter", function () {
  it("should increase the counter by a set amount of transactions", async function () {

    const txLimit = 2;

    const counterAddress = '0xb40a3bE7a402b4FBa84299E6c863060AC29Cc514';
    const counter = (await ethers.getContractAt("SimpleCounter", counterAddress)) as SimpleCounter;

    const signers = await ethers.getSigners();
    const deployer = signers[0].address;
    console.log("Deployer:", deployer);

    // const SimpleCounter = await ethers.getContractFactory("SimpleCounter");
    // const counter = await SimpleCounter.deploy();

    console.log('counter.address:', counter.address);

    const txs = [];

    let blockNumber = await ethers.provider.getBlockNumber();

    console.log('start @block:', blockNumber);

    let i = 0;

    const startTime = Date.now();

    const initialCount = await counter.getCount();

    while (i < txLimit) {
      // assume a gasLimit/block of 9m and a block time of 2s, that gives a 4.5m/s limit or 100 txs/second
      // hedera has a gasLimit of 15m/block, which for the most part is used on testnet so 9m is a fair assumption
      // note due to additional rate limits on the relay level, instead of 100 tx/s, only 50 tx/s is used as shown below
      txs.push(counter.increment({
        gasLimit: 45_000
      }));
      i++;

      // every 50 txs sleep for 1s before proceeding
      if (i%50 === 0) {
        await sleep(1_000);
      }
    }

    const endTime = Date.now();

    const timeToCreateAll = endTime - startTime;

    console.log('ms to create all:', timeToCreateAll);

    const finalTxs = await Promise.all(txs);

    for (const txIndex in finalTxs) {
      console.log(`tx ${txIndex}:`, finalTxs[txIndex].hash);
    }

    console.log('end @block:', blockNumber);

    const finalCount = await counter.getCount();

    expect(finalCount.sub(initialCount)).to.equal(txs.length);

  });
});
