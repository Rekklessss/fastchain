// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../contracts/WalletManager.sol";
import "../contracts/UserWallet.sol";
import "../lib/account-abstraction/contracts/core/EntryPoint.sol";

contract WalletManagerTest is Test {
    EntryPoint public entryPoint;
    WalletManager public walletManager;
    address public user;
    bytes public userProof;

    function setUp() public {
        // Deploy a new EntryPoint for testing
        entryPoint = new EntryPoint();
        // Deploy the WalletManager with the EntryPoint's address
        walletManager = new WalletManager(address(entryPoint));
        // Create a test user using Foundry's cheatcode (deterministic address)
        user = makeAddr("User");
        // Set up a dummy userProof (in practice, this comes from Anon-Aadhaar verification)
        userProof = hex"1234567890";
    }

    // Test that creating a wallet sets up the correct mappings and ownership.
    function testCreateWallet() public {
        string memory carId = "CAR1234";
        // Simulate the call coming from 'user'
        vm.prank(user);
        address walletAddr = walletManager.createWalletForCar(userProof, carId);
        
        // Verify the returned wallet address is not zero.
        assertTrue(walletAddr != address(0), "Wallet address should not be zero");

        // Verify that getWalletForCar returns the same address.
        address queriedWallet = walletManager.getWalletForCar(carId);
        assertEq(queriedWallet, walletAddr, "Queried wallet does not match deployed wallet");

        // Verify that getUserCars mapping for userProof includes this carId.
        string[] memory cars = walletManager.getUserCars(userProof);
        assertEq(cars.length, 1, "Expected one car in userCars mapping");
        assertEq(cars[0], carId, "Car ID mismatch in userCars mapping");

        // Verify the owner of the created UserWallet is 'user'
        UserWallet wallet = UserWallet(payable(walletAddr));
        assertEq(wallet.owner(), user, "UserWallet owner mismatch");
    }

    // Test that attempting to create a wallet for the same car ID twice reverts.
    function testDuplicateWalletFails() public {
        string memory carId = "CAR123";
        vm.prank(user);
        walletManager.createWalletForCar(userProof, carId);
        
        vm.prank(user);
        vm.expectRevert(WalletManager.WalletManager__WalletAlreadyExists.selector);
        walletManager.createWalletForCar(userProof, carId);
    }

    // Test that a single user (via one userProof) can have multiple car wallets.
    function testMultipleWalletsForSameUserProof() public {
        string memory carId1 = "CAR123";
        string memory carId2 = "CAR456";
        vm.startPrank(user);
        address walletAddr1 = walletManager.createWalletForCar(userProof, carId1);
        address walletAddr2 = walletManager.createWalletForCar(userProof, carId2);
        vm.stopPrank();

        // Verify that both wallets are created.
        string[] memory cars = walletManager.getUserCars(userProof);
        assertEq(cars.length, 2, "Expected two car IDs in userCars mapping");
        assertEq(cars[0], carId1, "First carId mismatch");
        assertEq(cars[1], carId2, "Second carId mismatch");

        // Verify the owner of each wallet is the user.
        UserWallet wallet1 = UserWallet(payable(walletAddr1));
        UserWallet wallet2 = UserWallet(payable(walletAddr2));
        assertEq(wallet1.owner(), user, "Wallet1 owner mismatch");
        assertEq(wallet2.owner(), user, "Wallet2 owner mismatch");
    }
}
