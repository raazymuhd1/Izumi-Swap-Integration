// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import { Test, console } from "forge-std/Test.sol";
// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import { IIzumiSwap } from "../../src/interfaces/IIzumiSwap.sol";
// import { IIzumiQuoter } from "../../src/interfaces/IIzumiQuoter.sol";
// import { IiZiSwapFactory } from "@izumi/contracts/core/interfaces/IiZiSwapFactory.sol";
// import { IiZiSwapPool } from "@izumi/contracts/core/interfaces/IiZiSwapPool.sol";
// import { MultihopSwap } from "../../src/MultihopSwap.sol";

// contract MultihopTest is Test {

//     MultihopSwap multihopSwap;
//     // SCROLL TESTNET SEPOLIA
//     address izumiRouterAddrScroll = 0x77132b63429718Db2B6ad8D942eE13A198f6Ab49;
//     address izumiQuoterScroll = 0xa9754f0D9055d14EB0D2d196E4C51d8B2Ee6f4d3;
//     address izumiFactoryScroll = 0x64c2F1306b4ED3183E7B345158fd01c19C0d8c5E;
//     // BSC TESTNET
//     address izumiRouterAddrBsc = 0x4bD007912911f3Ee4b4555352b556B08601cE7Ce;
//     address izumiQuoterBsc = 0x4bCACcF9A0FC3246449AC8A42A8918F2349Ed543;
//     address izumiFactoryBsc = 0x7fc0574eAe768B109EF38BC32665e6421c52Ee9d;

//     // tokens on bsc testnet supported by izumiSwap
//     address USER = 0xe8a00393a651A035fF0CD841c270d8a76529a4c2; // replace with ur address
//     address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
//     address IZI = 0x551197e6350936976DfFB66B2c3bb15DDB723250;
//     address USDT = 0x6AECfe44225A50895e9EC7ca46377B9397D1Bb5b;
//     address USDC = 0x876508837C162aCedcc5dd7721015E83cbb4e339; // usdc

//     uint128 test_amountIn = 0.009 ether;
//     uint24 swapFeeTestnet = 400; // 400/2000/10000 are supported fees


//     function setUp() public {
//         multihopSwap = new MultihopSwap(izumiRouterAddrBsc, izumiQuoterBsc, izumiFactoryBsc);
//         // vm.prank(USER);
//         // IERC20(WBNB).transfer(address(multihopSwap), test_amountIn);
//     }

//     function test_exactInputMultihop() public {
//         // pool that has some liq
//         //  WBNB/USDT pool: 0x8F4B2C26849C45f5D895fb04ab36437E11146332
//         //  WBNB/USDT pool: 0xf5fE40418Ec2b11F69F0B2c66058a00A1E7C21E2
//         //  USDT/USDC pool: 0xcE6Ffb9ea973B84A15a04D4ffb254151157F2709
//         vm.startPrank(USER);
//         IERC20(WBNB).approve(address(multihopSwap), test_amountIn);
//         MultihopSwap.ExactInputMultihopParams memory swapParams = MultihopSwap.ExactInputMultihopParams({
//             tokenIn: WBNB,
//             tokenOut: USDT,
//             poolToken: USDC,
//             amountIn: test_amountIn,
//             recipient: USER,
//             fee: swapFeeTestnet,
//             deadline: block.timestamp + 1 days
//         });
//         address poolAddr = IiZiSwapFactory(izumiFactoryBsc).pool(swapParams.tokenOut, swapParams.tokenIn, swapParams.fee);
//         uint256 tokenABalInpool = IERC20(swapParams.tokenIn).balanceOf(poolAddr);
//         uint256 tokenBBalInpool =  IERC20(swapParams.tokenOut).balanceOf(poolAddr);
//         console.log("pool addr ", poolAddr);
//         console.log("tokenA bal in pool", tokenABalInpool);
//         console.log("tokenB bal in pool", tokenBBalInpool);

//         uint256 amtOut = multihopSwap.exactInputMultihop(swapParams);
//         vm.stopPrank();

//         uint256 userBalanceOfTokenOut = IERC20(swapParams.tokenOut).balanceOf(USER);
//         console.log("tokenOut balance of user", userBalanceOfTokenOut);
//         console.log("amount out", amtOut);
//     }

//     function test_checkBalance() public {
//         uint256 bal = IERC20(WBNB).balanceOf(USER);
//         console.log(bal);
//     }

//     function test_exactOutputMultihop() public {
//         uint128 testAmountOut = 0.005 ether;

//         vm.startPrank(USER);

//         MultihopSwap.ExactOutputMultihopParams memory swapParams = MultihopSwap.ExactOutputMultihopParams({
//             tokenIn: WBNB,
//             tokenOut: IZI,
//             poolToken: USDT,
//             amountOut: testAmountOut,
//             recipient: USER,
//             fee: swapFeeTestnet,
//             deadline: block.timestamp
//         });
        // bytes memory path = abi.encodePacked(swapParams.tokenOut, swapFeeTestnet, swapParams.poolToken, swapFeeTestnet, swapParams.tokenIn);

         // quoting the swap, before actually calling swap
        // (uint256 cost, ) = IIzumiQuoter(izumiQuoterBsc).swapDesire(swapParams.amountOut, path);
//         IERC20(WBNB).approve(address(multihopSwap), cost); // cost maxAmountIn

//         address poolAddr = IiZiSwapFactory(izumiFactoryBsc).pool(swapParams.tokenIn, swapParams.tokenOut, swapParams.fee);
//         console.log("pool addr ", poolAddr);
//         uint256 amtOut = multihopSwap.exactOutputMultihop(swapParams);
//         vm.stopPrank();

//         console.log("amount user gets", amtOut);
//         // assert(amtOut > 0);
//     }

// }