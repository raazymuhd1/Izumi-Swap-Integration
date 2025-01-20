// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { MySwap } from "../../src/TestSwap.sol";
import { IiZiSwapFactory } from "@izumi/contracts/core/interfaces/IiZiSwapFactory.sol";
import { IIzumiQuoter } from "../../src/interfaces/IIzumiQuoter.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestSwapTest is Test {

    MySwap testSwap;

        // BSC TESTNET
    address izumiRouterAddrBsc = 0x4bD007912911f3Ee4b4555352b556B08601cE7Ce;
    address izumiQuoterBsc = 0x4bCACcF9A0FC3246449AC8A42A8918F2349Ed543;
    address izumiFactoryBsc = 0x7fc0574eAe768B109EF38BC32665e6421c52Ee9d;
    // SCROLL TESTNET SEPOLIA
    address izumiRouterAddrScroll = 0x77132b63429718Db2B6ad8D942eE13A198f6Ab49;
    address izumiQuoterScroll = 0xa9754f0D9055d14EB0D2d196E4C51d8B2Ee6f4d3;
    address izumiFactoryScroll = 0x64c2F1306b4ED3183E7B345158fd01c19C0d8c5E;

     // tokens on bsc testnet supported by izumiSwap
    address USER = 0xe8a00393a651A035fF0CD841c270d8a76529a4c2; // replace with ur address
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address IZI = 0x551197e6350936976DfFB66B2c3bb15DDB723250;
    address USDT = 0x6AECfe44225A50895e9EC7ca46377B9397D1Bb5b;
    address USDC = 0x876508837C162aCedcc5dd7721015E83cbb4e339; // usdc
    // params for scroll sepolia
    address WETH = 0x5300000000000000000000000000000000000004;
    address USDT_Scroll = 0x551197e6350936976DfFB66B2c3bb15DDB723250;
    address USDC_Scroll = 0x690000EF01deCE82d837B5fAa2719AE47b156697;

    uint128 test_amountIn = 0.009 ether;
    uint24 swapFeeTestnet = 400; // 400/2000/10000 are supported fees

    function setUp() public {
        // deploying contract
        testSwap = new MySwap(izumiRouterAddrBsc, izumiQuoterBsc, izumiFactoryBsc);
    }

    function testExactInput() public {
        MySwap.ExactInput memory swapParams = MySwap.ExactInput({
            tokenIn: WBNB,
            tokenOut: USDC,
            amountIn: test_amountIn
        });

        vm.startPrank(USER);
        IERC20(swapParams.tokenIn).approve(address(testSwap), swapParams.amountIn);
        uint256 outAmt = testSwap.exactInput(swapParams);

        address poolAddr = IiZiSwapFactory(izumiFactoryBsc).pool(swapParams.tokenOut, swapParams.tokenIn, 400);
        uint256 tokenABalInpool = IERC20(swapParams.tokenIn).balanceOf(poolAddr);
        uint256 tokenBBalInpool =  IERC20(swapParams.tokenOut).balanceOf(poolAddr);

        console.log("pool addr ", poolAddr);
        console.log("tokenA bal in pool", tokenABalInpool);
        console.log("tokenB bal in pool", tokenBBalInpool);

        uint256 userBalanceOfTokenOut = IERC20(swapParams.tokenOut).balanceOf(USER);
        console.log("tokenOut balance of user", userBalanceOfTokenOut);
        vm.stopPrank();

        console.log(outAmt);
    }


    function testExactOutput() public {
        uint128 amountOut = 0.005 ether;

        MySwap.ExactOutput memory swapParams = MySwap.ExactOutput({
            tokenIn: WBNB,
            tokenOut: USDT,
            amountOut: amountOut
        });
        bytes memory path = abi.encodePacked(swapParams.tokenOut, swapFeeTestnet, swapParams.tokenIn);

        vm.startPrank(USER);
         // quoting the swap, before actually calling swap
        (uint256 cost, ) = IIzumiQuoter(izumiQuoterBsc).swapDesire(swapParams.amountOut, path);
        IERC20(swapParams.tokenIn).approve(address(testSwap), cost);
        uint256 outAmt = testSwap.exactOutput(swapParams);

        address poolAddr = IiZiSwapFactory(izumiFactoryBsc).pool(swapParams.tokenIn, swapParams.tokenOut, 400);
        uint256 tokenABalInpool = IERC20(swapParams.tokenIn).balanceOf(poolAddr);
        uint256 tokenBBalInpool =  IERC20(swapParams.tokenOut).balanceOf(poolAddr);

        console.log("pool addr ", poolAddr);
        console.log("tokenA bal in pool", tokenABalInpool);
        console.log("tokenB bal in pool", tokenBBalInpool);

        uint256 userBalanceOfTokenOut = IERC20(swapParams.tokenOut).balanceOf(USER);
        console.log("tokenOut balance of user", userBalanceOfTokenOut);
        vm.stopPrank();

        console.log(outAmt);
    }
}