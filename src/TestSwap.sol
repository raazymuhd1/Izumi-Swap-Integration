// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseSwap } from "./BaseSwap.sol";
import { IIzumiQuoter } from "./interfaces/IIzumiQuoter.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MySwap is BaseSwap {

    uint24 private constant SWAPFEE_MAINNET = 3000; // supported fees on testnet 400/2000/
    uint24 private constant SWAPFEE_TESTNET = 400; // supported fees on testnet 400/2000/
    IIzumiQuoter private izumiQuoter;

    constructor(address izumiRouter, address izumiQouter_, address izumiPoolFactory) BaseSwap(izumiRouter, izumiQouter_, izumiPoolFactory) {
        izumiQuoter = IIzumiQuoter(izumiQouter_);
    }

     struct ExactInput {
        address tokenIn;
        address tokenOut;
        uint128 amountIn;
    }

     struct ExactOutput {
        address tokenIn;
        address tokenOut;
        uint128 amountOut;
    }

    /**
     @dev testing calling exactInput from base 
     @dev u don't need a quoter on this exactInput, coz user already input it by themself, therefore u can directly approving abstract contract to pull the amountIn of tokenIn
     */
    function exactInput(ExactInput memory params) external returns(uint256 outAmt) {

        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
        IERC20(params.tokenIn).approve(_getContractAddress(), params.amountIn);

        BaseSwap.ExactInputParams memory swapParams = BaseSwap.ExactInputParams({
            tokenIn: params.tokenIn,
            tokenOut: params.tokenOut,
            amountIn: params.amountIn,
            recipient: msg.sender,
            caller: address(this),
            fee: SWAPFEE_MAINNET,
            deadline: block.timestamp
        });

        uint256 amtOut = exactInput(swapParams);
        outAmt = amtOut;
    }

    /**
     @dev testing calling exactInput from base contract
     @dev u need to quote the swap on output one in order to get maxAmountIn based on user input of amountOut of tokenOut and approving abstract contract to pull those maxAmountIn returned by QUOTER
     */
    function exactOutput(ExactOutput memory params) external returns(uint256 outAmt) {
           // swap path for exactOutput in reverse order, this neeeded by quoter to pre-query the swap path to calculate the maxAmountIn user needs to pay  
        bytes memory path = abi.encodePacked(params.tokenOut, SWAPFEE_MAINNET, params.tokenIn);
        // cost = maxAmountIn (calculated by quoter based on user input amountOut)
        (uint256 cost, ) = izumiQuoter.swapDesire(params.amountOut, path);
        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), cost);
        IERC20(params.tokenIn).approve(_getContractAddress(), cost);

        BaseSwap.ExactOutputParams memory swapParams = BaseSwap.ExactOutputParams({
            tokenIn: params.tokenIn,
            tokenOut: params.tokenOut,
            amountOut: params.amountOut,
            recipient: msg.sender,
            caller: address(this),
            fee: SWAPFEE_MAINNET,
            deadline: block.timestamp
        });

        uint256 amtOut = exactOutput(swapParams);
        outAmt = amtOut;
    }
}