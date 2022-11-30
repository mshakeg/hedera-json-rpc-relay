//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Receiver {

    Donator immutable public donator;

    constructor(address _donator) {
      donator = Donator(_donator);
    }

    function redeemTinybar() public {
      donator.donateTinybar(address(this));
    }

    function redeemTinybarForSender() public {
      donator.donateTinybar(msg.sender);
    }

    function getBalance(address account) external view returns (uint256) {
      return account.balance;
    }

    fallback() external payable {
    }

    receive() external payable {
    }

}

contract Donator {

    constructor() payable {
      require(msg.value >= 1_000_000, "INSUFFICIENT_TINYBAR");
    }

    function donateTinybar(address recipient) public {
      if (!payable(recipient).send(1)) {
        revert("Transfer Failed");
      }
    }
}
