//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// this file is more or less identical to ./DelegateCall.sol; however has delegatecalls to the hts precompile
// https://github.com/hashgraph/hedera-services/tree/v0.34.5 disallows delegatecalls to the precompile

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import './_precompile-safe-hts/SafeHTS.sol';
import './_precompile-hts/HederaTokenService.sol';
import './_precompile-hts/HederaResponseCodes.sol';

interface ICallerHts {
    function depositCallback(address token, uint64 amount) external;
}

// routes calls via a Router
contract SuperRouterHts is ICallerHts {
    address public immutable routerAddress;
    address public immutable mockPrecompileAddress;

    constructor(address _routerAddress, address _precompileAddress) {
        routerAddress = _routerAddress;
        mockPrecompileAddress = _precompileAddress;
    }

    function normalDepositViaRouter(address token, uint64 amount) external {
        RouterHts(routerAddress).normalDeposit(token, amount);
    }

    function depositCallback(address token, uint64 amount) external override {}
}

contract RouterHts is ICallerHts, HederaTokenService {
    address public immutable coreAddress;
    address public immutable mockPrecompileAddress;

    bool internal isNormalDeposit;

    error HtsError(int responseCode);

    constructor(address _coreAddress, address _precompileAddress) {
        coreAddress = _coreAddress;
        mockPrecompileAddress = _precompileAddress;
    }

    function delegatedDeposit() external {
        isNormalDeposit = false;
        (bool success, ) = coreAddress.delegatecall(abi.encodeWithSignature('deposit(address,uint64)'));
        require(success, 'Delegatecall to Core failed');
    }

    function normalDeposit(address token, uint64 amount) external {
        isNormalDeposit = true;
        CoreHts(coreAddress).deposit(msg.sender, token, amount);
    }

    function normalWithdraw(address token, uint64 amount) external {
        CoreHts(coreAddress).withdraw(msg.sender, token, amount);
    }

    function depositCallback(address token, uint64 amount) external override {
        require(msg.sender == coreAddress, 'INVALID_CORE');
        int responseCode = HederaTokenService.delegateApprove(token, tx.origin, amount); // give tx.origin account unlimited spend on Core's token

        if (responseCode != HederaResponseCodes.SUCCESS) {
            revert HtsError(responseCode);
        }

        SafeHTS.safeTransferToken(token, tx.origin, coreAddress, int64(amount));
        // do other bad stuff here as Core by calling this callback allows for delegated priveleges to the Router even if malicious
    }
}

contract PrecompileHts {
    function precompile() external {}
}

contract CoreHts {
    mapping(address => mapping(address => uint64)) public vaultBalances;
    mapping(address => bool) public isAssociated;

    uint256 internal unlocked;

    error Locked();

    modifier lock() {
        if (unlocked == 2) revert Locked();
        unlocked = 2;
        _;
        unlocked = 1;
    }

    function associate(address token) external {
        if (!isAssociated[token]) {
            SafeHTS.safeAssociateToken(token, address(this));
            isAssociated[token] = true;
        }
    }

    function deposit(address owner, address token, uint64 amount) public lock {
        uint64 initialBalance = _balance(token);
        ICallerHts(msg.sender).depositCallback(token, amount);
        uint64 finalBalance = _balance(token);
        require(finalBalance >= (initialBalance + amount), "INSUFFICIENT_DEPOSIT");
        vaultBalances[token][owner] += amount;
    }

    function withdraw(address owner, address token, uint64 amount) public lock {
        require(tx.origin == owner, "NOT_OWNER");
        SafeHTS.safeTransferToken(token, address(this), owner, int64(amount));
        vaultBalances[token][owner] -= amount;
    }

    function _balance(address token) internal view returns (uint64 balance) {
        balance = uint64(IERC20(token).balanceOf(address(this)));
    }
}
