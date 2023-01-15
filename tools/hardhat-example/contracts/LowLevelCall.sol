// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// source: https://solidity-by-example.org/call/

contract LowLevelReceiver {

    event Received(address caller, uint256 amount, string message);

    fallback() external payable {
        emit Received(msg.sender, msg.value, 'Fallback was called');
    }

    function foo(string memory _message, uint256 _x) public payable returns (uint256) {
        emit Received(msg.sender, msg.value, _message);

        return _x + 1;
    }

    function viewCall(string memory _message, uint256 _x) public pure returns (uint256) {
        return _x + 1;
    }
}

contract Caller {
    event Response(bool success, bytes data);

    function testCallFoo(address payable _addr) public payable {
        // You can send ether and specify a custom gas amount

        if (isContract(_addr)) {
            (bool success, bytes memory data) = _addr.call{value: msg.value, gas: 20_000}(
                abi.encodeWithSignature('foo(string,uint256)', 'call foo', 123)
            );
            emit Response(success, data);
        }
    }

    function testCallViewCall(address payable _addr) public returns (bool success, bytes memory data) {
        // You can send ether and specify a custom gas amount
        if (isContract(_addr)) {
            (success, data) = _addr.call{gas: 20_000}(
                abi.encodeWithSignature('viewCall(string,uint256)', 'call foo', 123)
            );
        } else {
            success = true;
        }

    }

    // // Calling a function that does not exist triggers the fallback function.
    // function testCallDoesNotExist(address payable _addr) public payable {
    //     (bool success, bytes memory data) = _addr.call{value: msg.value}(abi.encodeWithSignature('doesNotExist()'));

    //     emit Response(success, data);
    // }

    // https://stackoverflow.com/a/73335577/10261711
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/a28aafdc85a592776544f7978c6b1a462d28ede2/contracts/utils/Address.sol#L40
    function isContract(address account) public view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

}
