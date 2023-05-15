import { ethers } from "hardhat";
import { expect } from "chai";

import { ContractFactory } from "@ethersproject/contracts";

import {
  deployOverrides
} from './utils';

import { SimpleCaller, SimpleStorage } from "../types";

let _simpleStorage: SimpleStorage;
let _simpleCaller: SimpleCaller;

const deploySimple = async (SimpleStorage: ContractFactory, SimpleCaller: ContractFactory) => {
  const simpleStorage = (await SimpleStorage.deploy(deployOverrides)) as SimpleStorage;

  const simpleStorageAddress = (await simpleStorage.deployTransaction.wait()).contractAddress;

  console.log('simpleStorageAddress:', simpleStorageAddress);

  _simpleStorage = SimpleStorage.attach(simpleStorageAddress) as SimpleStorage;

  const simpleCaller = (await SimpleCaller.deploy(deployOverrides)) as SimpleCaller;

  const simpleCallerAddress = (await simpleCaller.deployTransaction.wait()).contractAddress;

  console.log('simpleCallerAddress:', simpleCallerAddress);

  _simpleCaller = SimpleCaller.attach(simpleCallerAddress) as SimpleCaller;
};

describe("SimpleStorage", function () {
  before(async () => {

    const SimpleStorage = await ethers.getContractFactory("SimpleStorage");
    const SimpleCaller = await ethers.getContractFactory("SimpleCaller");

    await deploySimple(SimpleStorage, SimpleCaller);
  });

  // the staticChange function call reverts all state changes in updateNumberCallback
  it("should be able to make static call to function that reverts", async function () {
    const initialNumber = await _simpleStorage.number();
    const initialSquare = await _simpleStorage.square();

    expect(initialNumber).to.be.eq(0);
    expect(initialSquare).to.be.eq(0);

    const newNumber = 101;

    const res = await _simpleCaller.callStatic.staticChange(_simpleStorage.address, newNumber); // STATIC CALL

    const finalNumber = await _simpleStorage.number();
    const finalSquare = await _simpleStorage.square();

    expect(res).to.be.eq(newNumber);

    expect(finalNumber).to.be.eq(initialNumber, "static call should not change state");
    expect(finalSquare).to.be.eq(initialSquare, "static call should not change state");

  });

  it("should be able to make static call to function that does NOT revert", async function () {

    const initialNumber = await _simpleStorage.number();
    const initialSquare = await _simpleStorage.square();

    expect(initialNumber).to.be.eq(0);
    expect(initialSquare).to.be.eq(0);

    const newNumber = 101;

    const res = await _simpleStorage.callStatic.setNumber(newNumber); // STATIC CALL

    const finalNumber = await _simpleStorage.number();
    const finalSquare = await _simpleStorage.square();

    expect(res).to.be.eq(newNumber);

    expect(finalNumber).to.be.eq(initialNumber, "static call should not change state");
    expect(finalSquare).to.be.eq(initialSquare, "static call should not change state");

  });

  it("should be able to query state at specific block", async function () {

    let blockNumber1 = await ethers.provider.getBlockNumber();

    const initialNumber = await _simpleStorage.number();
    const initialSquare = await _simpleStorage.square();

    let blockNumber2 = await ethers.provider.getBlockNumber();

    expect(blockNumber2).to.be.greaterThanOrEqual(blockNumber1); // view calls do not advance on hardhat local node(only txs do), but may advance on the hedera local node; hence "gte" instead of just "equal to"

    expect(initialNumber).to.be.eq(0);
    expect(initialSquare).to.be.eq(0);

    const newNumber = 101;

    const tx = await _simpleStorage.setNumber(newNumber);
    await tx.wait(1);

    let blockNumber3 = await ethers.provider.getBlockNumber();

    expect(blockNumber3).to.be.greaterThan(blockNumber2);

    const finalNumber = await _simpleStorage.number();
    const finalSquare = await _simpleStorage.square();

    let blockNumber4 = await ethers.provider.getBlockNumber();

    expect(blockNumber4).to.be.greaterThanOrEqual(blockNumber3);

    expect(finalNumber).to.be.eq(newNumber, "expected number to be updated");
    expect(finalSquare).to.be.eq(newNumber ** 2, "expected square to be updated");

    const numberAtBlock1 = await _simpleStorage.number({
      blockTag: blockNumber1
    });
    const squareAtBlock1 = await _simpleStorage.square({
      blockTag: blockNumber1
    });

    expect(numberAtBlock1).to.be.eq(initialNumber);
    expect(squareAtBlock1).to.be.eq(initialSquare);

    const numberAtBlock3 = await _simpleStorage.number({
      blockTag: blockNumber3
    });
    const squareAtBlock3 = await _simpleStorage.square({
      blockTag: blockNumber3
    });

    expect(numberAtBlock3).to.be.eq(finalNumber);
    expect(squareAtBlock3).to.be.eq(finalSquare);
  });

});