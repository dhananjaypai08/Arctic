// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// --- Errors ---
error NotAuthorized();
error InvalidAmount();
error TransferFailed();
error AlreadyProcessed(uint256 nonce);
error NoFunctionNamed(bytes4 selector);