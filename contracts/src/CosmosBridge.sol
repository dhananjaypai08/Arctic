// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "./interfaces/IERC20.sol";
import {
    NotAuthorized,
    InvalidAmount,
    TransferFailed,
    AlreadyProcessed
} from "./errors/Index.sol";
import { BridgeRequest } from "./types/Index.sol";



contract CosmosBridge {
    address public admin;
    mapping(uint256 => bool) public processedNonces;

    event BridgeInitiated(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 toChainId,
        address toAddress,
        uint256 nonce
    );

    event BridgeCompleted(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 fromChainId,
        address fromAddress,
        uint256 nonce
    );

    address constant NATIVE_TOKEN = address(0);

    constructor() {
        admin = msg.sender;
    }

    // --- Initiate bridge (lock tokens or native ETH) ---
    function bridgeOut(
        address token,
        uint256 amount,
        uint256 toChainId,
        address toAddress,
        uint256 nonce
    ) external payable {
        if (amount == 0) revert InvalidAmount();
        if (processedNonces[nonce]) revert AlreadyProcessed(nonce);
        processedNonces[nonce] = true;

        if (token == NATIVE_TOKEN) {
            // Native ETH bridge: require msg.value == amount
            if (msg.value != amount) revert InvalidAmount();
        } else {
            if (msg.value != 0) revert InvalidAmount();
            if (!IERC20(token).transferFrom(msg.sender, address(this), amount)) revert TransferFailed();
        }

        emit BridgeInitiated(msg.sender, token, amount, toChainId, toAddress, nonce);
    }

    // --- Complete bridge (release tokens or native ETH) ---
    function bridgeIn(
        address user,
        address token,
        uint256 amount,
        uint256 fromChainId,
        address fromAddress,
        uint256 nonce
    ) external {
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

    // Allow contract to receive ETH
    receive() external payable {}
}