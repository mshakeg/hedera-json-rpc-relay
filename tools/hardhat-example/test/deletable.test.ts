import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Deletable__factory, DeletableFactory, DeletableFactory__factory } from '../types';
import { getHbarValue } from './utils';

describe('Investigate behaviour of contract deletion', function() {

  it('should be able to delete contract via Deletable#destroy()', async function() {

    const accounts = await ethers.getSigners();
    const account0 = accounts[0];

    const DeletableFactory = (await ethers.getContractFactory("DeletableFactory")) as DeletableFactory__factory;
    const deletableFactory = (await DeletableFactory.deploy()) as DeletableFactory;

    const createTx = await deletableFactory.createDeletable();
    const createRc = await createTx.wait();

    const deletableAddress = createRc.events?.[0].args?.['deletable'];

    let doesDeletableExist = await deletableFactory.doesDeletableExist(deletableAddress);

    expect(doesDeletableExist).to.be.eq(true);

    const Deletable = (await ethers.getContractFactory("Deletable")) as Deletable__factory;
    const deletable = Deletable.attach(deletableAddress);

    const closeTx = await deletable.destroy({value: getHbarValue(10) });
    const closeRc = await closeTx.wait();

    doesDeletableExist = await deletableFactory.doesDeletableExist(deletableAddress);
    expect(doesDeletableExist).to.be.eq(false);
  });

  it('should be able to delete deletable2 and re-create it', async function() {

    const accounts = await ethers.getSigners();
    const account0 = accounts[0];

    const DeletableFactory = (await ethers.getContractFactory("DeletableFactory")) as DeletableFactory__factory;
    const deletableFactory = (await DeletableFactory.deploy()) as DeletableFactory;

    let createTx = await deletableFactory.createDeletable2();
    let createRc = await createTx.wait();

    const deletable2Address = createRc.events?.[0].args?.['deletable'];

    let doesDeletable2Exist = await deletableFactory.doesDeletableExist2(deletable2Address);
    expect(doesDeletable2Exist).to.be.eq(true);

    await expect(deletableFactory.createDeletable2()).to.be.revertedWithoutReason;

    doesDeletable2Exist = await deletableFactory.doesDeletableExist2(deletable2Address);
    expect(doesDeletable2Exist).to.be.eq(true);

    const Deletable = (await ethers.getContractFactory("Deletable")) as Deletable__factory;
    const deletable2 = Deletable.attach(deletable2Address);

    let destroyTx = await deletable2.destroy({value: getHbarValue(10) });
    let destroyRc = await destroyTx.wait();

    doesDeletable2Exist = await deletableFactory.doesDeletableExist(deletable2Address);
    expect(doesDeletable2Exist).to.be.eq(false);

    createTx = await deletableFactory.createDeletable2();
    createRc = await createTx.wait();

    const deletable2AddressOnRecreate = createRc.events?.[0].args?.['deletable'];

    expect(deletable2Address).to.be.eq(deletable2AddressOnRecreate);

    doesDeletable2Exist = await deletableFactory.doesDeletableExist2(deletable2Address);
    expect(doesDeletable2Exist).to.be.eq(true);

    destroyTx = await deletable2.destroy({value: getHbarValue(10) });
    destroyRc = await destroyTx.wait();

    doesDeletable2Exist = await deletableFactory.doesDeletableExist(deletable2Address);
    expect(doesDeletable2Exist).to.be.eq(false);

    createTx = await deletableFactory.createDeletable2();
    createRc = await createTx.wait();

    const deletable2AddressOnRecreate2 = createRc.events?.[0].args?.['deletable'];

    expect(deletable2AddressOnRecreate2).to.be.eq(deletable2AddressOnRecreate);

  });

});
