// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import { MultihopSwap } from "./MultihopSwap.sol";

// contract testContractSwap is MultihopSwap {

//      struct ExactInputParams {
//         address tokenIn;
//         address tokenOut;
//         address poolToken;
//         uint128 amountIn;
//         // supported fee rates:
//         // for the MAINNET are 500 (0.05%), 3000 (0.3%), and 10000 (1%), other than that tx will revert;
//         // for the TESTNET are 400 (0.04%), 2000 (0.2%) and 10000 (1%)
//         address swapRouter;
//         address swapQuoter;
//         address swapPoolFactory;
//         uint256 deadline;
//     }

//     function exactInput(ExactInputParams memory params) external {
//         MultihopSwap.ExactInputMultihopParams memory swapParams = MultihopSwap.ExactInputMultihopParams({
//             tokenIn: params.tokenIn,
//             tokenOut: params.tokenOut,
//             poolToken: params.poolToken,
//             amountIn: params.amountIn,
//             recipient: msg.sender,
//             fee: 400,
//             deadline: params.deadline
//         });

//         // uint256 amtOut = exactInputMultihop(swapParams);
//     }
// }