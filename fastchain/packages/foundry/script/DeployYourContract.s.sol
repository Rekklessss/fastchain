// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import "../contracts/WalletManager.sol";
import {ScaffoldETHDeploy} from "./DeployHelpers.s.sol";
// Import the EntryPoint from your account-abstraction library
import "../lib/account-abstraction/contracts/core/EntryPoint.sol";

/**
 * @notice Deploy script for WalletManager contract.
 * @dev This script deploys an EntryPoint contract first and then deploys WalletManager
 *      using the EntryPoint's address.
 */
contract DeployYourContract is ScaffoldETHDeploy {
    function run() external ScaffoldEthDeployerRunner {
        // Deploy the EntryPoint contract first
        EntryPoint entryPoint = new EntryPoint();
        console.logString(string.concat("EntryPoint deployed at: ", vm.toString(address(entryPoint))));
        
        // Now deploy WalletManager with the EntryPoint address
        WalletManager walletManager = new WalletManager(address(entryPoint));
        console.logString(string.concat("WalletManager deployed at: ", vm.toString(address(walletManager))));
    }
}
