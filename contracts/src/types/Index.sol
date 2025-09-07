// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// --- Types ---
struct BridgeRequest {
    address user;
    address token;
    uint256 amount;
    uint256 toChainId;
    address toAddress;
    uint256 nonce;
}