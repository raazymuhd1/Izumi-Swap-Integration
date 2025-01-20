// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { MySwap } from "../../src/TestSwap.sol";
import { IiZiSwapFactory } from "@izumi/contracts/core/interfaces/IiZiSwapFactory.sol";
import { IIzumiQuoter } from "../../src/interfaces/IIzumiQuoter.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestSwapTestBob is Test {

    MySwap testSwap;

        // izumi contracts on BOB mainnet
    address izumiRouterAddrBob = 0x3EF68D3f7664b2805D4E88381b64868a56f88bC4;
    address izumiQuoterBob = 0x33531bDBFE34fa6Fd5963D0423f7699775AacaaF;
    address izumiFactoryBob = 0x8c7d3063579BdB0b90997e18A770eaE32E1eBb08;
    address USER = 0xe8a00393a651A035fF0CD841c270d8a76529a4c2;

    // tokens on BOB mainnet
    address WETH = 0x4200000000000000000000000000000000000006;
    address WBTC = 0x03C7054BCB39f7b2e5B2c7AcB37583e32D70Cfa3;
    address USDT = 0x05D032ac25d322df992303dCa074EE7392C117b9;
    address USDCe = 0xe75D0fB2C24A55cA1e3F96781a2bCC7bdba058F0;
    address DAI = 0x6c851F501a3F24E29A8E39a29591cddf09369080;
    address SLERF = 0x6db2721586abCC682b44C5425B97f3c27ffB5b27;
    address STONE = 0x96147A9Ae9a42d7Da551fD2322ca15B71032F342;
    address tBTC = 0xBBa2eF945D523C4e2608C9E1214C2Cc64D4fc2e2;
    address rETH = 0xB5686c4f60904Ec2BDA6277d6FE1F7cAa8D1b41a;

    uint128 test_amountIn = 5e6 ;
    uint24 SWAPFEE_TESTNET = 400; // 400/2000/10000 are supported fees
    uint24 SWAPFEE_MAINNET = 3000; // 400/2000/10000 are supported fees

    function setUp() public {
        testSwap = new MySwap(izumiRouterAddrBob, izumiQuoterBob, izumiFactoryBob);
    }

    function test_exactInputBob() public {
        uint128 amountIn = 0.0015 ether;
        // MAINNET POOL
        // USDT/WBTC pool on mainnet: 0xF84F0CFAf83daE9141E1bAd4c8Df7035De7A4133 (not enough liq) 
        // USDT/WETH pool: 0x2A786b1EEA0CD8b0D8ca5C2dcB5bAE8f857695e0
        // WETH/USDT pool: 0x2A786b1EEA0CD8b0D8ca5C2dcB5bAE8f857695e0
        // WETH/USDCe pool: 0xa7dA499dE9a74886DAFf90f65F78A7039De7fAe5
        // WETH/WBTC pool: 0xCC2AcdDbbf2C15e680C4480B449e94d4df53c0eF
        // WETH/DAI pool: 0x262d95EC345FdD7Ec033D44a5090ee78c278c38b
        // WETH/SLERF pool: 0x6d6EF20Da013f0F2a32C18BAdAb6E9d0CFefd1E1
        // USDT/USDCe pool: 0xC8aD303D7f50C8D57658FF25b0D565eD6db328ea
        // USDT/DAI pool: 0xa0eA50a41997e5eF8B2648Cfea8643165D7aBA2d
        // USDT/SLERF pool: 0xce81938411461e3A9fb82F7ca3770004F7D054Ec  (not enough liq) (revert with "PR")
        // WETH/STONE pool: 0x075A20731B59A7e17105462F66a065aD34675066  (no liq) (revert with "PR")
        // USDT/STONE pool: 0xAF72d843FE2cbb4E9630e0a1183188a8d6593959  (no liq) (revert with "PR")
        MySwap.ExactInput memory swapParams = MySwap.ExactInput({
            tokenIn: WETH,
            tokenOut: DAI,
            amountIn: amountIn
        });

        vm.startPrank(USER);
        // approving testSwap contract to pull the token
        IERC20(swapParams.tokenIn).approve(address(testSwap), swapParams.amountIn);
        // calling for swap
        uint256 outAmt = testSwap.exactInput(swapParams);

        address poolAddr = IiZiSwapFactory(izumiFactoryBob).pool(swapParams.tokenOut, swapParams.tokenIn, SWAPFEE_MAINNET);
        uint256 tokenABalInpool = IERC20(swapParams.tokenIn).balanceOf(poolAddr);
        uint256 tokenBBalInpool =  IERC20(swapParams.tokenOut).balanceOf(poolAddr);

        console.log("pool addr ", poolAddr);
        console.log("tokenA bal in pool", tokenABalInpool);
        console.log("tokenB bal in pool", tokenBBalInpool);

        uint256 userBalanceOfTokenOut = IERC20(swapParams.tokenOut).balanceOf(USER);
        console.log("tokenOut balance of user", userBalanceOfTokenOut);
        vm.stopPrank();

        console.log("amount acquired", outAmt);
    }

    function test_exactOutputBob() public {
                // MAINNET POOL
        // USDT/WBTC pool on mainnet: 0xF84F0CFAf83daE9141E1bAd4c8Df7035De7A4133 (not enough liq) 
        // USDT/WETH pool: 0x2A786b1EEA0CD8b0D8ca5C2dcB5bAE8f857695e0
        // WETH/USDT pool: 0x2A786b1EEA0CD8b0D8ca5C2dcB5bAE8f857695e0
        // WETH/USDCe pool: 0xa7dA499dE9a74886DAFf90f65F78A7039De7fAe5
        // WETH/WBTC pool: 0xCC2AcdDbbf2C15e680C4480B449e94d4df53c0eF
        // USDT/USDCe pool: 0xC8aD303D7f50C8D57658FF25b0D565eD6db328ea
        // USDT/DAI pool: 0xa0eA50a41997e5eF8B2648Cfea8643165D7aBA2d
        // USDT/SLERF pool: 0xce81938411461e3A9fb82F7ca3770004F7D054Ec  (not enough liq) 
        // WETH/STONE pool: 0x075A20731B59A7e17105462F66a065aD34675066  (no liq) 
        // USDT/STONE pool: 0xAF72d843FE2cbb4E9630e0a1183188a8d6593959  (no liq) 
        uint128 amountOut = 4e6;
        uint24 swapFeeMainnet = 3000;

        MySwap.ExactOutput memory swapParams = MySwap.ExactOutput({
            tokenIn: WETH,
            tokenOut: DAI,
            amountOut: amountOut
        });
        bytes memory path = abi.encodePacked(swapParams.tokenOut, SWAPFEE_MAINNET, swapParams.tokenIn);

        vm.startPrank(USER);
         // quoting the swap, before actually calling swap
        (uint256 cost, ) = IIzumiQuoter(izumiQuoterBob).swapDesire(swapParams.amountOut, path);
        IERC20(swapParams.tokenIn).approve(address(testSwap), cost);
        uint256 outAmt = testSwap.exactOutput(swapParams);

        address poolAddr = IiZiSwapFactory(izumiFactoryBob).pool(swapParams.tokenIn, swapParams.tokenOut, SWAPFEE_MAINNET);
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