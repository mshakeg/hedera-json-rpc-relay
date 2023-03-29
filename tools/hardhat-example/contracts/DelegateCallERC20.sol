//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// this file is very similar to ./DelegateCall.sol; however investigates malicious delegatecall ERC20 actions
// specifically ERC20#approval() and then in another separate tx #transferFrom()
// @note: delegatecall on ERC20#transferFrom() may be possible in the callback; however since balance checks are normally done in the function that called the callback after the callback has executed there's no point as that'll cause the tx to revert
// also since delegatecall only executes the code of the called contract since it may ONLY potentially change the storage of the Caller contract there's NO possibility of a similar attack that occurred on Hedera(see delegate-call-hts.sol) from occurring on Ethereum

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "hardhat/console.sol";

contract DollarToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("DollarToken", "USDT") {
        _mint(msg.sender, initialSupply);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        console.log("in DT approve; sender: %s", msg.sender);
        console.log("in DT approve; spender: %s", spender);
        super.approve(spender, amount);
    }
}

interface ICallerERC20 {
    function depositCallback(address token, uint amount) external;
}

contract RouterERC20 is ICallerERC20 {
    address public immutable coreAddress;
    address public immutable mockPrecompileAddress;

    bool internal isNormalDeposit;

    constructor(address _coreAddress, address _precompileAddress) {
        coreAddress = _coreAddress;
        mockPrecompileAddress = _precompileAddress;
    }

    function normalDeposit(address token, uint amount) external {
        isNormalDeposit = true;
        CoreERC20(coreAddress).deposit(msg.sender, token, amount);
    }

    function maliciousDeposit(address token, uint amount) external {
        console.log("in maliciousDeposit");
        isNormalDeposit = false;
        CoreERC20(coreAddress).deposit(msg.sender, token, amount);
    }

    function normalWithdraw(address token, uint amount) external {
        CoreERC20(coreAddress).withdraw(msg.sender, token, amount);
    }

    function depositCallback(address token, uint amount) external override {
        require(msg.sender == coreAddress, 'INVALID_CORE');
        DollarToken(token).transferFrom(tx.origin, msg.sender, amount);

        if (!isNormalDeposit) { // malicious deposit that also attempts to approve the tx.origin to spend from Core
            address spender = tx.origin;
            bytes memory approveEncoding = abi.encodeWithSignature("approve(address,uint256)", spender, amount);
            (bool success, ) = token.delegatecall(approveEncoding);
            require(success, "APPROVE_FAILED");
            uint allowance = DollarToken(token).allowance(msg.sender, spender);
            // allowance should be 0 since delegatecall modifies Caller storage
            require(allowance == 0, "NOT_ALLOWED");
            console.log("in malicious depositCallback: %s", allowance);
        }

    }
}

contract CoreERC20 {
    mapping(address => mapping(address => uint)) public vaultBalances;
    mapping(address => bool) public isAssociated;

    uint256 internal unlocked;

    error Locked();

    modifier lock() {
        if (unlocked == 2) revert Locked();
        unlocked = 2;
        _;
        unlocked = 1;
    }

    function deposit(address owner, address token, uint amount) public lock {
        uint initialBalance = _balance(token);
        ICallerERC20(msg.sender).depositCallback(token, amount);
        uint finalBalance = _balance(token);
        require(finalBalance >= (initialBalance + amount), "INSUFFICIENT_DEPOSIT");
        vaultBalances[token][owner] += amount;
    }

    function withdraw(address owner, address token, uint amount) public lock {
        require(tx.origin == owner, "NOT_OWNER");

        // ERC20#transfer() is used instead of ERC20#transferFrom() as the latter considers spend allowances;
        // which for address(this) defaults to 0 unless approved;
        // which is redundant as #transfer() assumes address(this) and hence only needs to consider balances and address(this) should be allowed to spend all of its balances
        DollarToken(token).transfer(owner, amount);
        vaultBalances[token][owner] -= amount;
    }

    function _balance(address token) internal view returns (uint balance) {
        balance = IERC20(token).balanceOf(address(this));
    }
}
