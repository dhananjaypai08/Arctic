
require('dotenv').config();
const { ethers } = require("ethers");
const fs = require("fs");
const path = require("path");

const CHAINS = [
  {
    name: "Local/Testnet",
    chainId: 262144,
    rpcUrl: "http://localhost:8545",
    deployInfo: "contracts/broadcast/DeployCosmosBridge.sol/262144/run-latest.json"
  },
  {
    name: "Sepolia",
    chainId: 11155111,
    rpcUrl: "https://sepolia.infura.io/v3/2WCbZ8YpmuPxUtM6PzbFOfY5k4B",
    deployInfo: "contracts/broadcast/DeployCosmosBridge.sol/11155111/run-latest.json"
  }
];

const ABI_PATH = "contracts/out/CosmosBridge.sol/CosmosBridge.json";
const abi = JSON.parse(fs.readFileSync(ABI_PATH)).abi;

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const COSMOS_PRIVATE_KEY = process.env.COSMOS_PRIVATE_KEY;

if (!COSMOS_PRIVATE_KEY) {
  throw new Error("Set COSMOS_PRIVATE_KEY in your environment");
}
if (!PRIVATE_KEY) {
  throw new Error("Set PRIVATE_KEY in your environment");
}

    function getContractAddress(deployInfoPath) {
      const deployData = JSON.parse(fs.readFileSync(deployInfoPath));
      const tx = deployData.transactions.find(t => t.contractName === "CosmosBridge");
      return tx.contractAddress;
    }

    async function getLegacyGasOptions(provider) {
      const gasPrice = await provider.getGasPrice();
      return {
        gasPrice,
        type: 0 // legacy without EIP1559 fields
      };
    }

    async function main() {
      const src = CHAINS[1]; // Sepolia
      const dst = CHAINS[0]; // Local/Testnet

      const srcProvider = new ethers.JsonRpcProvider(src.rpcUrl);
      const dstProvider = new ethers.JsonRpcProvider(dst.rpcUrl);
      const srcWallet = new ethers.Wallet(PRIVATE_KEY, srcProvider);
      const dstWallet = new ethers.Wallet(COSMOS_PRIVATE_KEY, dstProvider);

      const srcBridgeAddr = getContractAddress(src.deployInfo);
      const dstBridgeAddr = getContractAddress(dst.deployInfo);

      // Attach contracts
      const srcBridge = new ethers.Contract(srcBridgeAddr, abi, srcWallet);
      const dstBridge = new ethers.Contract(dstBridgeAddr, abi, dstWallet);


      // Use address(0) for native ETH bridging
      const NATIVE_TOKEN = ethers.ZeroAddress;
      const isNative = true; // set to false for ERC20 bridging

      // You can toggle between native and ERC20 bridging here
      // Note the oracle problem for this type of canonical bridge still isn't solved here
      const token = isNative ? NATIVE_TOKEN : "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238";
      const amount = ethers.parseUnits("0.01", 18); // 0.01 ETH or 0.01 tokens
      const toChainId = dst.chainId;
      const toAddress = await dstWallet.getAddress();
      const nonce = Date.now();

      console.debug("Source Bridge:", srcBridgeAddr);
      console.debug("Destination Bridge:", dstBridgeAddr);
      console.debug("Token:", token);
      console.debug("Amount:", amount.toString());
      console.debug("ToChainId:", toChainId);
      console.debug("ToAddress:", toAddress);
      console.debug("Nonce:", nonce);

      if (!isNative) {
        const erc20Abi = ["function approve(address spender, uint256 amount) external returns (bool)"];
        const tokenContract = new ethers.Contract(token, erc20Abi, srcWallet);
        const approveTx = await tokenContract.approve(srcBridgeAddr, amount);
        await approveTx.wait();
        console.log("Approved bridge to spend tokens.");
      }

      let tx;
      if (isNative) {
        tx = await srcBridge.bridgeOut(token, amount, toChainId, toAddress, nonce, { value: amount });
      } else {
        tx = await srcBridge.bridgeOut(token, amount, toChainId, toAddress, nonce);
      }
      await tx.wait();
      console.log(`bridgeOut called on ${src.name} (${src.chainId})`);

      let txOpts = {};
      if (dst.name === "Local/Testnet" || dst.chainId === 262144) {
        txOpts = await getLegacyGasOptions(dstProvider);
        txOpts.gasLimit = 500000;
      }

      const user = await srcWallet.getAddress();
      let bridgeInTx;
      if (isNative) {
        bridgeInTx = await dstBridge.bridgeIn(user, token, amount, src.chainId, user, nonce, txOpts);
      } else {
        bridgeInTx = await dstBridge.bridgeIn(user, token, amount, src.chainId, user, nonce, txOpts);
      }
      await bridgeInTx.wait();
      console.log(`bridgeIn called on ${dst.name} (${dst.chainId})`);

      console.log("Bridge test complete.");
    }

    main().catch(console.error);