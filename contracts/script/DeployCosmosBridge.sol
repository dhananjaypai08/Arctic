// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {CosmosBridge} from "../src/CosmosBridge.sol";

contract CosmosBridgeScript is Script {
    CosmosBridge public cosmosBridge;

    function setUp() public {}

    function run() public {
        address privateKey = vm.addr(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(privateKey);

        cosmosBridge = new CosmosBridge();

        vm.stopBroadcast();
        console.log("The contract has been deployed:", address(cosmosBridge));
    }
}
