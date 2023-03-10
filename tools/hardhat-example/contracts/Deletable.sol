//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract DeletableFactory {

    mapping(address => bool) public doesDeletableExist;
    mapping(address => bool) public doesDeletableExist2;

    event CreateDeletable(address deletable);

    function createDeletable() public {
        address deletable = address(new Deletable(msg.sender, false));
        doesDeletableExist[deletable] = true;
        emit CreateDeletable(deletable);
    }

    function clearDeletable() public {
        require(doesDeletableExist[msg.sender], "NOT_VALID_DELETABLE");
        doesDeletableExist[msg.sender] = false;
    }

    function createDeletable2() public {

        bytes memory _deployData = abi.encode(msg.sender, true);
        bytes32 salt = keccak256(_deployData);

        address deletable2 = address(new Deletable{salt: salt}(msg.sender, true));

        doesDeletableExist2[deletable2] = true;
        emit CreateDeletable(deletable2);
    }

    function clearDeletable2() public {
        require(doesDeletableExist2[msg.sender], "NOT_VALID_DELETABLE");
        doesDeletableExist2[msg.sender] = false;
    }

}

contract Deletable {
    address payable immutable admin;
    DeletableFactory immutable factory;
    bool immutable isDeletable2;

    // a predefined address that identifies the sender as the Hedera network
    address constant HEDERA_NETWORK = address(1);

    modifier onlyHedera() {
        require(msg.sender == HEDERA_NETWORK, "NOT_HEDERA_NETWORK");
        _;
    }

    modifier onlyAdmin() {
      require(msg.sender == admin, "NOT_ADMIN");
      _;
    }

    constructor(address _admin, bool _isDeletable2) payable {
        admin = payable(_admin);
        factory = DeletableFactory(msg.sender);
        isDeletable2 = _isDeletable2;
    }

    function destroy() onlyAdmin public payable {
        cleanup();
        selfdestruct(admin);
    }

    function cleanup() internal {
        if (isDeletable2) {
            factory.clearDeletable2();
        } else {
            factory.clearDeletable();
        }
    }

    receive() external payable {
        // Handle incoming Ether here
    }

    fallback() external payable {
        // This function is called when the contract receives Ether
        // with no function call specified.
        // Any Ether received is transferred to the contract owner.
        admin.transfer(msg.value);
    }
}