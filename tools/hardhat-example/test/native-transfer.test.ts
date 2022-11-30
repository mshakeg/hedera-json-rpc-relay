import { expect } from "chai";
import { Contract, ContractFactory, BigNumber, Signer } from "ethers";
import { ethers } from "hardhat";

import {
  Receiver,
  Receiver__factory,
  Donator,
  Donator__factory,
} from "../types";
import { defaultOverrides, getHbarValue, FunctionArgs } from "./utils";

async function getHederaDeployAddress(contract: Contract): Promise<string> {
  return (await contract.deployTransaction.wait()).contractAddress;
}

async function deployToHedera(
  Contract: ContractFactory,
  args: FunctionArgs = [],
  overrides: {
    from?: Signer;
    gasLimit?: number;
    value?: BigNumber;
  } = {
    gasLimit: 1_000_000,
  }
): Promise<Contract> {
  const contract = await Contract.deploy(...args, overrides);
  const contractAddress = await getHederaDeployAddress(contract); // hedera contract address corresponds with the account id not the create1 address on typical evm chains
  return Contract.attach(contractAddress);
}

describe("NativeTransfer", function () {
  let Receiver: Receiver__factory;
  let Donator: Donator__factory;

  let receiver: Receiver;
  let donator: Donator;

  let defaultAccountInfo: { accountId: string; address: string; signer?: Signer } = {
    accountId: "",
    address: "",
  };

  before(async () => {
    const accounts = await ethers.getSigners();

    defaultAccountInfo.signer = accounts[0];
    defaultAccountInfo.address = accounts[0].address;

    Receiver = await ethers.getContractFactory("Receiver");
    Donator = await ethers.getContractFactory("Donator");

    donator = (await deployToHedera(Donator, [], {value: getHbarValue(10) })) as Donator;
    receiver = (await deployToHedera(Receiver, [donator.address])) as Receiver;
  });

  describe("Valid actions", async () => {
    console.log("in valid actions");

    it("Should be able to get tinybar donated to Receiver contract and msg.sender", async () => {

      const startingReceiverNativeBalance = await receiver.getBalance(receiver.address);
      const startingDonatorNativeBalance = await receiver.getBalance(donator.address);

      console.log('here 1');

      const tx = await receiver.redeemTinybar({
        ...defaultOverrides,
        from: defaultAccountInfo.address
      });

      console.log('here 2');
      // tx reverts with error string: "Transfer Failed"

      await tx.wait();

      console.log('here 3');

      const finalReceiverNativeBalance = await receiver.getBalance(receiver.address);
      const finalDonatorNativeBalance = await receiver.getBalance(donator.address);

      expect(startingReceiverNativeBalance.add(1)).to.be.eq(
        finalReceiverNativeBalance,
        "Receiver contract native balance didn't update correctly"
      );

      expect(startingDonatorNativeBalance.sub(1)).to.be.eq(
        finalDonatorNativeBalance,
        "Donator contract native balance didn't update correctly"
      );

      // do redeemTinybarForSender next
    });
  });

});
