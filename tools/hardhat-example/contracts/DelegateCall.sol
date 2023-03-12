//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import 'hardhat/console.sol';

interface ICaller {
    function callback() external;
}

// routes calls via a Router
contract SuperRouter is ICaller {
    address public immutable routerAddress;
    address public immutable precompileAddress;

    constructor(address _routerAddress, address _precompileAddress) {
        routerAddress = _routerAddress;
        precompileAddress = _precompileAddress;
    }

    function routeViaRouter() external {
        console.log('in SuperRouter#routeViaRouter; origin is %s', tx.origin);

        Router(routerAddress).route();
    }

    function callback() external override {
        console.log('in SuperRouter#callback; origin is %s', tx.origin);
        console.log('in SuperRouter#callback; sender is %s', msg.sender);

        (bool success, ) = precompileAddress.delegatecall(abi.encodeWithSignature('fee()'));
    }
}

contract Router is ICaller {
    address public immutable coreAddress;
    address public immutable precompileAddress;

    bool internal isNormalRoute;

    constructor(address _coreAddress, address _precompileAddress) {
        coreAddress = _coreAddress;
        precompileAddress = _precompileAddress;
    }

    function route() external {
        isNormalRoute = false;

        console.log('in Router#route; Core address is %s', coreAddress);
        console.log('in Router#route; this address is %s', address(this));

        (bool success, ) = coreAddress.delegatecall(abi.encodeWithSignature('core()'));
        require(success, 'Delegatecall to Core failed');
    }

    function normalRoute() external {
        isNormalRoute = true;

        Core(coreAddress).core();
    }

    function callback() external override {
        console.log('in Router#callback; origin is %s', tx.origin);
        console.log('in Router#callback; sender is %s', msg.sender);

        (bool success, ) = precompileAddress.delegatecall(abi.encodeWithSignature('precompile()'));
    }
}

contract Precompile {
    function precompile() external {
        console.log('in Precompile#precompile; origin is %s', tx.origin);
        console.log('in Precompile#precompile; sender is %s', msg.sender);
    }
}

contract Core {
    function core() external {
		console.log('in Core#core; this is %s', address(this)); /// @dev this changes not !Core.address if delegatecall??
        console.log('in Core#core; origin is %s', tx.origin);
        console.log('in Core#core; sender is %s', msg.sender);

        ICaller(msg.sender).callback();
    }
}
