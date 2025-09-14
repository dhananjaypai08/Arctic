// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Errors ---
error NotAuthorized();
error InvalidAmount();
error TransferFailed();
error AlreadyProcessed(uint256 nonce);
error NoFunctionNamed(bytes4 selector);