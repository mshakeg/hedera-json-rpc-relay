// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'hedera-smart-contracts/hts-precompile/IHederaTokenService.sol';
import 'hedera-smart-contracts/hts-precompile/KeyHelper.sol';
import './utils/HederaTokenUtils.sol';
import './utils/HederaFungibleTokenUtils.sol';

// TODO: refactor for actions to be standalone internal functions with assertions inside
// TODO: do validation on token at creation
// TODO: complete other precompile contracts implementation and test suite
// TODO: do validations in _precheck functions such that never reverts with error strings in ERC{20/721}
// TODO: investigate ordering of response codes on Hedera and adjust ordering in mocks accordingly
// TODO: investigate permissions that tx.origin is granted in precompile mock and adjust authorization accordingly if required
// TODO: test all token keys
// TODO: evaluate code coverage of all tests
// TODO: add deploy contracts scripts for hedera testnet and mainnet

contract HederaFungibleTokenTest is HederaTokenUtils, HederaFungibleTokenUtils, KeyHelper {
    address alice = vm.addr(1);
    address bob = vm.addr(2);
    address carol = vm.addr(3);
    address dave = vm.addr(4);

    // setUp is executed before each and every test function
    function setUp() public {

        _setUpHtsPrecompileMock();

        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(carol, 100 ether);
        vm.deal(dave, 100 ether);
    }

    // positive cases
    function test_CreateHederaFungibleTokenViaHtsPrecompile() public {
        address sender = alice;
        string memory name = 'Token A';
        string memory symbol = 'TA';
        address treasury = alice;
        int64 initialTotalSupply = 1e16;
        int32 decimals = 8;

        _doCreateHederaFungibleTokenViaHtsPrecompile(sender, name, symbol, treasury, initialTotalSupply, decimals);
    }

    function test_CreateHederaFungibleTokenDirectly() public {
        address sender = alice;
        string memory name = 'Token A';
        string memory symbol = 'TA';
        address treasury = alice;
        int64 initialTotalSupply = 1e16;
        int32 decimals = 8;

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](0);

        _doCreateHederaFungibleTokenDirectly(sender, name, symbol, treasury, initialTotalSupply, decimals, keys);
    }

    function test_ApproveViaHtsPrecompile() public {
        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](0);
        address tokenAddress = _createSimpleMockFungibleToken(alice, keys);

        uint allowance = 1e8;
        _doApproveViaHtsPrecompile(alice, tokenAddress, bob, allowance);
    }

    function test_ApproveDirectly() public {
        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](0);
        address tokenAddress = _createSimpleMockFungibleToken(alice, keys);

        uint allowance = 1e8;
        _doApproveDirectly(alice, tokenAddress, bob, allowance);
    }

    function test_TransferViaHtsPrecompile() public {
        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](0);
        address tokenAddress = _createSimpleMockFungibleToken(alice, keys);

        bool success;
        uint256 amount = 1e8;

        TransferParams memory transferParams = TransferParams({
            sender: alice,
            token: tokenAddress,
            from: alice,
            to: bob,
            amount: amount
        });

        (success, ) = _doTransferViaHtsPrecompile(transferParams);
        assertEq(success, false, 'expected transfer to fail since recipient is not associated with token');

        success = _doAssociateViaHtsPrecompile(bob, tokenAddress);
        assertEq(success, true, 'expected bob to associate with token');

        (success, ) = _doTransferViaHtsPrecompile(transferParams);
        assertEq(success, true, 'expected transfer to succeed');
    }

    function test_TransferDirectly() public {
        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](0);
        address tokenAddress = _createSimpleMockFungibleToken(alice, keys);

        bool success;
        uint256 amount = 1e8;

        TransferParams memory transferParams = TransferParams({
            sender: alice,
            token: tokenAddress,
            from: alice,
            to: bob,
            amount: amount
        });

        (success, ) = _doTransferDirectly(transferParams);
        assertEq(success, false, 'expected transfer to fail since recipient is not associated with token');

        success = _doAssociateViaHtsPrecompile(bob, tokenAddress);
        assertEq(success, true, 'expected bob to associate with token');

        (success, ) = _doTransferDirectly(transferParams);
        assertEq(success, true, 'expected transfer to succeed');
    }

    function test_TransferUsingAllowanceViaHtsPrecompile() public {
        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](0);
        address tokenAddress = _createSimpleMockFungibleToken(alice, keys);

        bool success;
        uint256 amount = 1e8;

        TransferParams memory transferParams = TransferParams({
            sender: bob,
            token: tokenAddress,
            from: alice,
            to: bob,
            amount: amount
        });

        (success, ) = _doTransferViaHtsPrecompile(transferParams);
        assertEq(success, false, 'expected transfer to fail since bob is not associated with token');

        success = _doAssociateViaHtsPrecompile(bob, tokenAddress);
        assertEq(success, true, 'expected bob to associate with token');

        (success, ) = _doTransferViaHtsPrecompile(transferParams);
        assertEq(success, false, 'expected transfer to fail since bob is not granted an allowance');

        uint allowance = 1e8;
        _doApproveViaHtsPrecompile(alice, tokenAddress, bob, allowance);

        (success, ) = _doTransferViaHtsPrecompile(transferParams);
        assertEq(success, true, 'expected transfer to succeed');
    }

    function test_TransferUsingAllowanceDirectly() public {

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](0);
        address tokenAddress = _createSimpleMockFungibleToken(alice, keys);

        bool success;
        uint256 amount = 1e8;

        TransferParams memory transferParams = TransferParams({
            sender: bob,
            token: tokenAddress,
            from: alice,
            to: bob,
            amount: amount
        });

        (success, ) = _doTransferDirectly(transferParams);
        assertEq(success, false, 'expected transfer to fail since bob is not associated with token');

        success = _doAssociateViaHtsPrecompile(bob, tokenAddress);
        assertEq(success, true, 'expected bob to associate with token');

        (success, ) = _doTransferDirectly(transferParams);
        assertEq(success, false, 'expected transfer to fail since bob is not granted an allowance');

        uint allowance = 1e8;
        _doApproveViaHtsPrecompile(alice, tokenAddress, bob, allowance);

        (success, ) = _doTransferDirectly(transferParams);
        assertEq(success, true, 'expected transfer to succeed');
    }

    /// @dev there is no test_CanMintDirectly as the ERC20 standard does not typically allow direct mints
    function test_CanMintViaHtsPrecompile() public {

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](1);
        keys[0] = KeyHelper.getSingleKey(KeyHelper.KeyType.SUPPLY, KeyHelper.KeyValueType.CONTRACT_ID, alice);
        address tokenAddress = _createSimpleMockFungibleToken(alice, keys);

        _doAssociateViaHtsPrecompile(bob, tokenAddress);

        bool success;

        int64 mintAmount = 1e8;

        MintResponse memory mintResponse;
        MintParams memory mintParams;

        mintParams = MintParams({
            sender: bob,
            token: tokenAddress,
            mintAmount: mintAmount
        });

        mintResponse = _doMintViaHtsPrecompile(mintParams);
        assertEq(mintResponse.success, false, "expected mint to fail since bob is not supply key");

        mintParams = MintParams({
            sender: alice,
            token: tokenAddress,
            mintAmount: mintAmount
        });

        mintResponse = _doMintViaHtsPrecompile(mintParams);
        assertEq(mintResponse.success, true, "expected mint to succeed");
    }

    /// @dev there is no test_CanBurnDirectly as the ERC20 standard does not typically allow direct burns
    function test_CanBurnViaHtsPrecompile() public {

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](0);
        address tokenAddress = _createSimpleMockFungibleToken(alice, keys);

        bool success;

        int64 burnAmount = 1e8;

        (success, ) = _doBurnViaHtsPrecompile(bob, tokenAddress, burnAmount);
        assertEq(success, false, "expected burn to fail since bob is not treasury");

        (success, ) = _doBurnViaHtsPrecompile(alice, tokenAddress, burnAmount);
        assertEq(success, true, "expected mint to succeed");
    }

    // negative cases
    function test_CannotApproveIfSpenderNotAssociated() public {
        /// @dev already demonstrated in some of the postive test cases
        // cannot approve spender if spender is not associated with HederaFungibleToken BOTH directly and viaHtsPrecompile
    }

    function test_CannotTransferIfRecipientNotAssociated() public {
        /// @dev already demonstrated in some of the postive test cases
        // cannot transfer to recipient if recipient is not associated with HederaFungibleToken BOTH directly and viaHtsPrecompile
    }
}

// forge test --match-contract HederaFungibleTokenTest --match-test test_CanBurnViaHtsPrecompile -vv
// forge test --match-contract HederaFungibleTokenTest -vv