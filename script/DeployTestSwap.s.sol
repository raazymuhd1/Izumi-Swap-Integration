// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { MySwap } from "../src/TestSwap.sol";

contract DeployMySwap is Script {
    
    address izumiRouterAddrBob = 0x3EF68D3f7664b2805D4E88381b64868a56f88bC4;
    address izumiQuoterBob = 0x33531bDBFE34fa6Fd5963D0423f7699775AacaaF;
    address izumiFactoryBob = 0x8c7d3063579BdB0b90997e18A770eaE32E1eBb08;
    MySwap mySwap;

    // first deployed: 0xa0Df0E51847D68F5a5d6CCb0e76E150012CA849D
    // sec deployed: 0x0B113Fba9514e4f9E9B7c6ff586f29aEd72d8cDa

    function run() public returns(address) {

      vm.startBroadcast();
        mySwap = new MySwap(izumiRouterAddrBob, izumiQuoterBob, izumiFactoryBob);
      vm.stopBroadcast();

      console.log("contract addr", address(mySwap));
      console.log("contract is deployed");

      return address(mySwap);
    }
}