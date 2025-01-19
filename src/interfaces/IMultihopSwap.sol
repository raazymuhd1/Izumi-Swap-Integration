// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMultihopSwap {

    struct ExactInputMultihopParams {
        address tokenIn;
        address tokenOut;
        address poolToken; // token in the middle of the path (WBNB, WETH, USDT, USDC, WBTC), not liq pool token
        uint128 amountIn;
        address recipient;
        // supported fee rates:
        // for the MAINNET are 500 (0.05%), 3000 (0.3%), and 10000 (1%), other than that tx will revert;
        // for the TESTNET are 400 (0.04%), 2000 (0.2%) and 10000 (1%)
        uint24 fee;
        uint256 deadline;
    }

    struct ExactOutputMultihopParams {
        address tokenIn;
        address tokenOut;
        address poolToken; // token in the middle of the path (WBNB, WETH, USDT, USDC, WBTC), not liq pool token
        uint128 amountOut;
        address recipient;
        // supported fee rates:
        // for the MAINNET are 500 (0.05%), 3000 (0.3%), and 10000 (1%), other than that tx will revert;
        // for the TESTNET are 400 (0.04%), 2000 (0.2%) and 10000 (1%)
        uint24 fee;
        uint256 deadline;
    }

     function exactInputMultihop(ExactInputMultihopParams memory params) external returns(uint256 amtOut);

    function exactOutputMultihop(ExactOutputMultihopParams memory params) external returns(uint256 amtOut);
}