// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "./interfaces/IERC20.sol";
import {ICosmosBridge} from "./interfaces/ICosmosBridge.sol";
import {
    NotAuthorized,
    InvalidAmount,
    TransferFailed,
    AlreadyProcessed
} from "./errors/Index.sol";
import { BridgeRequest } from "./types/Index.sol";

/// @author DJ
/// @title CosmosBridge
/// @notice Cross-chain bridge contract for Cosmos-EVM and EVM-compatible networks
/// @dev Supports bridging of both native ETH and ERC20 tokens. Only the admin can complete incoming transfers.
contract CosmosBridge is ICosmosBridge {
    /// @notice Admin address with permission to complete incoming bridge transfers
    address public admin;

    /// @notice Tracks processed nonces to prevent replay attacks
    mapping(uint256 => bool) public processedNonces;

    /// @notice Special address to represent native ETH bridging
    address constant NATIVE_TOKEN = address(0);

    /// @notice Sets the admin to the contract deployer
    constructor() {
        admin = msg.sender;
    }

    /// @notice Initiates a bridge transfer by locking tokens or native ETH
    /// @param token The address of the token to bridge (use address(0) for native ETH)
    /// @param amount The amount of tokens or ETH to bridge
    /// @param toChainId The destination chain ID
    /// @param toAddress The recipient address on the destination chain
    /// @param nonce A unique nonce for this transfer
    /// @dev Emits a BridgeInitiated event. For native ETH, msg.value must equal amount.
    function bridgeOut(
        address token,
        uint256 amount,
        uint256 toChainId,
        address toAddress,
        uint256 nonce
    ) external payable override {
        if (amount == 0) revert InvalidAmount();
        if (processedNonces[nonce]) revert AlreadyProcessed(nonce);
        processedNonces[nonce] = true;

        if (token == NATIVE_TOKEN) {
            if (msg.value != amount) revert InvalidAmount();
        } else {
            if (msg.value != 0) revert InvalidAmount();
            if (!IERC20(token).transferFrom(msg.sender, address(this), amount)) revert TransferFailed();
        }

        emit BridgeInitiated(msg.sender, token, amount, toChainId, toAddress, nonce);
    }

    /// @notice Completes a bridge transfer by releasing tokens or native ETH to the user
    /// @param user The recipient address on this chain
    /// @param token The address of the token to release (address(0) for native ETH)
    /// @param amount The amount of tokens or ETH to release
    /// @param fromChainId The source chain ID
    /// @param fromAddress The sender address on the source chain
    /// @param nonce The unique nonce for this transfer
    /// @dev Only callable by the admin. Emits a BridgeCompleted event.
    function bridgeIn(
        address user,
        address token,
        uint256 amount,
        uint256 fromChainId,
        address fromAddress,
        uint256 nonce
    ) external override {
        if (msg.sender != admin) revert NotAuthorized();
        if (processedNonces[nonce]) revert AlreadyProcessed(nonce);
        processedNonces[nonce] = true;

        if (token == NATIVE_TOKEN) {
            (bool sent, ) = user.call{value: amount}("");
            if (!sent) revert TransferFailed();
        } else {
            if (!IERC20(token).transfer(user, amount)) revert TransferFailed();
        }

        emit BridgeCompleted(user, token, amount, fromChainId, fromAddress, nonce);
    }

    /// @notice Allows the contract to receive ETH
    receive() external payable {}
}