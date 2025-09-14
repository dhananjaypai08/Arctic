// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title ICosmosBridge
/// @notice Interface for CosmosBridge contract, including all events and functions
interface ICosmosBridge {
    /// @notice Emitted when a bridge transfer is initiated
    event BridgeInitiated(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 toChainId,
        address toAddress,
        uint256 nonce
    );

    /// @notice Emitted when a bridge transfer is completed
    event BridgeCompleted(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 fromChainId,
        address fromAddress,
        uint256 nonce
    );

    function bridgeOut(
        address token,
        uint256 amount,
        uint256 toChainId,
        address toAddress,
        uint256 nonce
    ) external payable;

    function bridgeIn(
        address user,
        address token,
        uint256 amount,
        uint256 fromChainId,
        address fromAddress,
        uint256 nonce
    ) external;
}