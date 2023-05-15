// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract SimpleCaller {

    // call this function to simulate static call
    function staticChange(address ssAddress, uint256 _number) public returns (uint256 a)
    {
        try SimpleStorage(ssAddress).updateNumber(_number) {} catch (bytes memory reason) {
            if (reason.length == 0) { // condition is true when SimpleStorage.updateNumber function is stateful
                return (404);
            }

            a = abi.decode(reason, (uint256));
        }
    }

    // this function is called by SimpleStorage.updateNumber and reverts with the simulated number
    function updateNumberCallback(uint256 _number) public pure {
        assembly {
            let ptr := mload(0x20)
            mstore(ptr, _number)
            revert(ptr, 32)
        }
    }
}

contract SimpleStorage {
    uint256 public number;
    uint256 public square;

    function updateNumber(uint256 _number) external returns (uint256) {

        square = _number ** 2; // state changing statement; callStatic works when this line is commented out

        SimpleCaller(msg.sender).updateNumberCallback(_number);
        return number;
    }

    function setNumber(uint256 _number) external returns (uint256) {
        square = _number ** 2;
        number = _number;
        return number;
    }
}