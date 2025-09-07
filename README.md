# Cosmos-EVM Bridge

## Overview
This project provides a simple, production-grade interface and smart contract for bridging assets between Cosmos/EVM-based networks and other EVM-compatible L1/L2 chains (such as Ethereum, Arbitrum, Optimism, etc). The goal is to make cross-chain transfers seamless, especially for web2-native users who want to create their own native L1 and enable cross-chain communication and asset movement.

## Features
- **Seamless bridging** between Cosmos/EVM and any EVM-compatible L1/L2
- **Simple interface** for web2 developers and users
- **Production-grade Solidity contracts** with reverts, interfaces, and types
- **Easy deployment and integration**

## How It Works
1. **Lock or burn** tokens on the source chain using the bridge contract.
2. **Emit an event** with transfer details (amount, destination chain, recipient, etc).
3. **Off-chain relayer** or oracle observes the event and triggers a mint/unlock on the destination chain.
4. **User receives tokens** on the destination chain.

## Getting Started

### Start a local evm node
```sh
git submodule update --init --recursive
cd evm && ./local_node.sh # add your own moniker, chainId, coin denom in ./local_node.sh file
```
*Note*: This starts your rpc url on localhost:8545

### 1. Deploy the Bridge Contract
Deploy the `CosmosBridge` contract to your source and destination EVM chains. You can use Foundry, Hardhat, or any EVM-compatible deployment tool.

### 2. Configure the Bridge
- Set up relayers to listen for bridge events and relay them across chains.
- Configure the contract addresses and chain IDs for each network.

### 3. Transfer Assets
- Call the `bridgeOut` function on the source chain to initiate a transfer.
- The relayer will call `bridgeIn` on the destination chain to complete the transfer.

### 4. Example Usage
```solidity
// Lock tokens on source chain
bridge.bridgeOut(token, amount, toChainId, toAddress, nonce);

// Relayer completes transfer on destination chain
bridge.bridgeIn(user, token, amount, fromChainId, fromAddress, nonce);
```

## Contract Addresses
Below are the deployed contract addresses for each supported chain. These are auto-generated from the deployment artifacts in `broadcast/DeployCosmosBridge/`:

| Chain Name      | Chain ID   | Contract Address                        |
|----------------|-----------|-----------------------------------------|
| Local/Testnet  | 262144    | 0x66f0c4c9a21b78d4d92358d087176964982e1c21 |
| Sepolia        | 11155111  | 0x18bf120e15abc83ae150a74fdd5cec9938e67c36 |


## For Web2 Developers
- You can use this bridge to create your own native L1 and connect it to the EVM ecosystem.
- The interface is simple and can be integrated into web apps, wallets, or backend services.
- All you need is a wallet and RPC endpoint for each chain.

## Security
- Only trusted relayers should be allowed to call `bridgeIn`.
- Always use unique nonces to prevent replay attacks.
- Audit your contracts before deploying to mainnet.