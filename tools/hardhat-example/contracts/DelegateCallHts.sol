//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// this file is more or less identical to ./DelegateCall.sol; however has the calls to the hts precompile

interface ICallerHts {
    function callback() external;
}

// routes calls via a Router
contract SuperRouterHts is ICallerHts {
    address public immutable routerAddress;
    address public immutable precompileAddress;

    constructor(address _routerAddress, address _precompileAddress) {
        routerAddress = _routerAddress;
        precompileAddress = _precompileAddress;
    }

    function routeViaRouter() external {
        RouterHts(routerAddress).route();
    }

    function callback() external override {
        (bool success, ) = precompileAddress.delegatecall(abi.encodeWithSignature('fee()'));
    }
}

contract RouterHts is ICallerHts {
    address public immutable coreAddress;
    address public immutable precompileAddress;

    bool internal isNormalRoute;

    constructor(address _coreAddress, address _precompileAddress) {
        coreAddress = _coreAddress;
        precompileAddress = _precompileAddress;
    }

    function route() external {
        isNormalRoute = false;
        (bool success, ) = coreAddress.delegatecall(abi.encodeWithSignature('core()'));
        require(success, 'Delegatecall to Core failed');
    }

    function normalRoute() external {
        isNormalRoute = true;

        CoreHts(coreAddress).core();
    }

    function callback() external override {
        (bool success, ) = precompileAddress.delegatecall(abi.encodeWithSignature('precompile()'));
    }
}

contract PrecompileHts {
    function precompile() external {
    }
}

contract CoreHts {
    function core() external {

        ICallerHts(msg.sender).callback();
    }
}
