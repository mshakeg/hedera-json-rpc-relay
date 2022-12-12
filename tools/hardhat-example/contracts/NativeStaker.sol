//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @notice NativeStaker is an admin controlled contract which stakes to an admin selected node
/// other accounts/contracts that delegate their stake to a NativeStaker essentially has the NativeStaker earn their native staking rewards
contract NativeStaker {

    bool constant public isNativeStaker = true;

    constructor() payable {}
}

contract StakeToNativeStaker {

    NativeStaker immutable nativeStaker;

    constructor(address _nativeStaker) payable {

        NativeStaker __nativeStaker = NativeStaker(_nativeStaker);
        require(__nativeStaker.isNativeStaker() == true, "NOT_NATIVE_STAKER");

        nativeStaker = __nativeStaker;
    }

}
