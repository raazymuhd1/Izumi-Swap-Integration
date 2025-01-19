// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { MultihopSwap } from "./MultihopSwap.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestContractSwap is MultihopSwap {

    uint24 swapFee = 400; // supported fees on testnet 400/2000/10000

    constructor(address izumiRouter, address izumiQouter, address izumiPoolFactory) MultihopSwap(izumiRouter, izumiQouter, izumiPoolFactory) {

    }

     struct ExactInputParams {
        address tokenIn;
        address tokenOut;
        address poolToken; // middle path token (WETH/WBNB/WBTC/USDT/USDC), not liq pool token
        uint128 amountIn;
    }

    /**
     @dev testing calling exactInput from base contract
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
            fee: swapFee,
            deadline: block.timestamp
        });

        uint256 amtOut = exactInputMultihop(swapParams);
        outAmt = amtOut;
    }
}