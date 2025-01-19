// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { MultihopSwap } from "./MultihopSwap.sol";
import { IIzumiQuoter } from "./interfaces/IIzumiQuoter.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestContractSwap is MultihopSwap {

    uint24 swapFee = 400; // supported fees on testnet 400/2000/
    IIzumiQuoter private izumiQuoter;

    constructor(address izumiRouter, address izumiQouter_, address izumiPoolFactory) MultihopSwap(izumiRouter, izumiQouter_, izumiPoolFactory) {
        izumiQuoter = IIzumiQuoter(izumiQouter_);
    }

     struct ExactInputParams {
        address tokenIn;
        address tokenOut;
        address poolToken; // middle path token (WETH/WBNB/WBTC/USDT/USDC), not liq pool token
        uint128 amountIn;
    }

     struct ExactOutputParams {
        address tokenIn;
        address tokenOut;
        address poolToken; // middle path token (WETH/WBNB/WBTC/USDT/USDC), not liq pool token
        uint128 amountOut;
    }

    /**
     @dev testing calling exactInput from base 
     @dev u don't need a quoter on this exactInput, coz user already input it by themself, therefore u can directly approving abstract contract to pull the amountIn of tokenIn
     */
    function exactInput(ExactInputParams memory params) external returns(uint256 outAmt) {

        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
        IERC20(params.tokenIn).approve(_getContractAddress(), params.amountIn);

        MultihopSwap.ExactInputMultihopParams memory swapParams = MultihopSwap.ExactInputMultihopParams({
            tokenIn: params.tokenIn,
            tokenOut: params.tokenOut,
            poolToken: params.poolToken,
            amountIn: params.amountIn,
            recipient: msg.sender,
            caller: address(this),
            fee: swapFee,
            deadline: block.timestamp
        });

        uint256 amtOut = exactInputMultihop(swapParams);
        outAmt = amtOut;
    }

    /**
     @dev testing calling exactInput from base contract
     @dev u need to quote the swap on output one in order to get maxAmountIn based on user input of amountOut of tokenOut and approving abstract contract to pull those maxAmountIn returned by QUOTER
     */
    function exactOutput(ExactOutputParams memory params) external returns(uint256 outAmt) {
           // swap path for exactOutput in reverse order, this neeeded by quoter to pre-query the swap path to calculate the maxAmountIn user needs to pay  
        bytes memory path = abi.encodePacked(params.tokenOut, uint24(swapFee),  params.poolToken, uint24(swapFee), params.tokenIn);
        // cost = maxAmountIn (calculated by quoter based on user input amountOut)
        (uint256 cost, ) = izumiQuoter.swapDesire(params.amountOut, path);
        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), cost);
        IERC20(params.tokenIn).approve(_getContractAddress(), cost);

        MultihopSwap.ExactInputMultihopParams memory swapParams = MultihopSwap.ExactOutputMultihopParams({
            tokenIn: params.tokenIn,
            tokenOut: params.tokenOut,
            poolToken: params.poolToken,
            amountOut: params.amountOut,
            recipient: msg.sender,
            caller: address(this),
            fee: swapFee,
            deadline: block.timestamp
        });

        uint256 amtOut = exactOutputMultihop(swapParams);
        outAmt = amtOut;
    }
}