// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IIzumiSwap } from "../../src/interfaces/IIzumiSwap.sol";
import { IIzumiQuoter } from "../../src/interfaces/IIzumiQuoter.sol";
import { IiZiSwapFactory } from "@izumi/contracts/core/interfaces/IiZiSwapFactory.sol";
import { IiZiSwapPool } from "@izumi/contracts/core/interfaces/IiZiSwapPool.sol";
import { MultihopSwap } from "../../src/MultihopSwap.sol";

contract MultihopTest is Test {
    // izumi swapRouter on scroll: 0x77132b63429718Db2B6ad8D942eE13A198f6Ab49
    // izumi swapRouter on bsc: 0x4bD007912911f3Ee4b4555352b556B08601cE7Ce
    // 

    MultihopSwap multihopSwap;
    address izumiRouterAddrScroll = 0x77132b63429718Db2B6ad8D942eE13A198f6Ab49;
    address izumiRouterAddrBsc = 0x4bD007912911f3Ee4b4555352b556B08601cE7Ce;
    address izumiQuoterBsc = 0x4bCACcF9A0FC3246449AC8A42A8918F2349Ed543;
    address izumiFactoryBsc = 0x7fc0574eAe768B109EF38BC32665e6421c52Ee9d;
    address USER = 0xe8a00393a651A035fF0CD841c270d8a76529a4c2;
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address IZI = 0x551197e6350936976DfFB66B2c3bb15DDB723250;
    address USDT = 0x6AECfe44225A50895e9EC7ca46377B9397D1Bb5b;
    address USDC = 0x876508837C162aCedcc5dd7721015E83cbb4e339; // usdc
    uint128 test_amountIn = 0.009 ether;

    uint24 swapFeeTestnet = 400; // 400/2000/10000 are supported fees


    function setUp() public {
        multihopSwap = new MultihopSwap(izumiRouterAddrBsc, izumiQuoterBsc, izumiFactoryBsc);
        // vm.prank(USER);
        // IERC20(WBNB).transfer(address(multihopSwap), test_amountIn);
    }

    function test_exactInputMultihop() public {
         bytes memory path = abi.encodePacked(WBNB, uint24(400), USDT, uint24(400), USDC);

        //  WBNB/USDT pool: 0x8F4B2C26849C45f5D895fb04ab36437E11146332
        //  USDT/USDC pool: 0xcE6Ffb9ea973B84A15a04D4ffb254151157F2709

        vm.startPrank(USER);
        IERC20(WBNB).approve(address(multihopSwap), test_amountIn);
        (uint256 acquire, ) = IIzumiQuoter(izumiQuoterBsc).swapAmount(test_amountIn, path);
        MultihopSwap.ExactInputMultihopParams memory swapParams = MultihopSwap.ExactInputMultihopParams({
            tokenIn: WBNB,
            tokenOut: USDC,
            poolToken: USDT,
            amountIn: test_amountIn,
            recipient: USER,
            fee: swapFeeTestnet,
            deadline: block.timestamp + 1 days
        });
        address poolAddr = IiZiSwapFactory(izumiFactoryBsc).pool(USDT, WBNB, swapParams.fee);
        uint256 tokenABalInpool = IERC20(WBNB).balanceOf(poolAddr);
        uint256 tokenBBalInpool =  IERC20(IZI).balanceOf(poolAddr);

        uint256 amtOut = multihopSwap.exactInputMultihop(swapParams);
        console.log("pool addr ", poolAddr);
        console.log("tokenA bal in pool", tokenABalInpool);
        console.log("tokenB bal in pool", tokenBBalInpool);
        vm.stopPrank();

        uint256 userBalanceOfTokenOut = IERC20(swapParams.tokenOut).balanceOf(USER);
        console.log("tokenOut balance of user", userBalanceOfTokenOut);
        console.log("acquire amount", acquire);
        console.log("amount out", amtOut);
    }

    function test_checkBalance() public {
        uint256 bal = IERC20(WBNB).balanceOf(USER);
        console.log(bal);
    }

    function test_exactOutputMultihop() public {
        bytes memory path = abi.encodePacked(WBNB, uint24(400), USDT, uint24(400), USDC);
        uint128 testAmountOut = 0.005 ether;

        vm.startPrank(USER);
        IERC20(WBNB).approve(address(multihopSwap), test_amountIn);
        (uint256 cost, ) = IIzumiQuoter(izumiQuoterBsc).swapDesire(testAmountOut, path);

        MultihopSwap.ExactOutputMultihopParams memory swapParams = MultihopSwap.ExactOutputMultihopParams({
            tokenIn: WBNB,
            tokenOut: USDC,
            poolToken: IZI,
            amountOut: testAmountOut,
            maxAmountIn: cost,
            recipient: USER,
            fee: swapFeeTestnet,
            swapRouter: izumiRouterAddrBsc,
            swapQuoter: izumiQuoterBsc,
            deadline: block.timestamp
        });
          address poolAddr = IiZiSwapFactory(izumiFactoryBsc).pool(WBNB, USDT, swapParams.fee);
        console.log("pool addr ", poolAddr);
        uint256 amtOut = multihopSwap.exactOutputMultihop(swapParams);
        console.log("max amountIn", cost);
        vm.stopPrank();
        // console.log(amtOut);
        // assert(amtOut > 0);
    }

}