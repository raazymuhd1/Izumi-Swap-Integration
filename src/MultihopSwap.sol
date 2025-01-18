// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IIzumiSwap } from "./interfaces/IIzumiSwap.sol";
import { IIzumiQuoter } from "./interfaces/IIzumiQuoter.sol";
import { IiZiSwapFactory } from "@izumi/contracts/core/interfaces/IiZiSwapFactory.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
    @dev making a multihop swap abstract contract that can be inherits from by other contracts later on.
    @notice for slippage protection will need an off-chain sdk or on-chain price oracle (chainlink) to check the expected price of tokenIn
    @notice current issues are both function still error
    @dev need an example contract to inherit from this abstract contract later

    REQUIREMENTS
    needed an abstract contract actually, for a swap from token A to token B using Izumi finance
    budget around 300$ , just one function needed that should work where these params are passed 

    1: Recipient 
    2: Token A (amount In)
    3: Token B (Minimun amount out)
    4: Token Payer
    5: Swap router
 */

contract MultihopSwap {

    error MultihopSwap_InvalidCaller(address caller);
    error MultihopSwap_ExactInputSwapFailed(address user, uint256 amountIn, uint256 amountOut);
    error MultihopSwap_ExactOutputSwapFailed(address user, uint256 amountIn, uint256 amountOut);
    error MultihopSwap_InvalidToken(address tokenIn, address tokenOut);
    error MultihopSwap_NotEnoughAmount(uint256 amount);
    error MultihopSwap_InvalidRecipient(address rec);

    IIzumiSwap private s_izumiRouter;
    IIzumiQuoter private s_izumiQuoter;
    IiZiSwapFactory private s_izumiFactory;

    // ---------------------------------------------- EVENTS ---------------------------------------------------------
    event SwapExactInputSuccessfull(address tokenA, address tokenB, uint128 amountIn, address recipient);
    event SwapExactOutputSuccessfull(address tokenA, address tokenB, uint256 amountOut, address recipient);

    constructor(address swapRouter_, address swapQuoter, address swapPoolFactory_) {
        s_izumiRouter = IIzumiSwap(swapRouter_);
        s_izumiQuoter = IIzumiQuoter(s_izumiQuoter);
        s_izumiFactory = IiZiSwapFactory(swapPoolFactory_);
    }

    // --------------------------------------------- STRUCTS ---------------------------------------------------------
    // all these params grouped together to avoid stack too deep error from EVM
    struct ExactInputMultihopParams {
        address tokenIn;
        address tokenOut;
        address poolToken;
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
        address poolToken;
        uint128 amountOut;
        uint256 maxAmountIn; // max amount of token user willing to pay for swapped with tokenOut
        address recipient;
        // supported fee rates:
        // for the MAINNET are 500 (0.05%), 3000 (0.3%), and 10000 (1%), other than that tx will revert;
        // for the TESTNET are 400 (0.04%), 2000 (0.2%) and 10000 (1%)
        uint24 fee;
        address swapRouter; // izumi swap router
        address swapQuoter; // izumi swap quoter
        uint256 deadline;
    }

    struct PoolCheckParams {
        address tokenOut; 
        address tokenIn;
        uint24 fee;
        uint256 amountIn; 
        uint256 minAmtOut;
    }

    // --------------------------------------------MODIFIERS-------------------------------------------------------
    modifier ValidCaller() {
        // using IF instead of REQUIRE for gas opt, REQUIRE much expensive than IF
        if(msg.sender == address(0)) revert MultihopSwap_InvalidCaller(msg.sender);
        _;
    }

     // --------------------------------------------INTERNAL & PRIVATE FUNCTIONS -------------------------------------------------------

    /**
        @dev check if the pool exist or not, if pool not exist the swap will fail
     */
     function poolExists(PoolCheckParams memory poolParams) internal view returns(address pool) {
         address poolAddr = s_izumiFactory.pool(poolParams.tokenOut, poolParams.tokenIn, poolParams.fee);
         if(poolAddr == address(0)) revert("pool not exists");
        
        uint256 poolTokenABal = IERC20(poolParams.tokenIn).balanceOf(poolAddr);
        uint256 poolTokenBBal = IERC20(poolParams.tokenOut).balanceOf(poolAddr);

        if(poolTokenABal <= 0 || poolTokenBBal <= 0) revert("pool token balance is zero"); 
        if(poolTokenABal <= poolParams.amountIn || poolTokenBBal <= poolParams.minAmtOut) revert("one of the pool tokens liquidity is less than the expected token amount");
         
     }

    /**
        @notice uses swapDesire/swapAmount function from izumiFinance to make a multihop , or we can use swapAmountSingleInternal function in Quoter contract
        @dev IMPORTANT! - needs to add a pool and poolLiquidity before calling swap, to make sure the pool exist and has enough liq
        @param params - see ExactInputMultihopParams struct for params
        @return amtOut - an amount user gets after swapping
     */
    function exactInputMultihop(ExactInputMultihopParams memory params) external ValidCaller returns(uint256 amtOut) {
        // swap path
        bytes memory path = abi.encodePacked(params.tokenIn, uint24(params.fee), params.poolToken, uint24(params.fee), params.tokenOut);

        // address check
        if(params.tokenIn == address(0) || params.tokenOut == address(0)) revert MultihopSwap_InvalidToken(params.tokenIn, params.tokenOut);
        if(params.recipient == address(0)) revert MultihopSwap_InvalidRecipient(params.recipient);
        if(params.amountIn <= 0) revert MultihopSwap_NotEnoughAmount(params.amountIn);

        // the caller must approve this contract to pull the tokenIn amount
        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
        // approving izumiRouter tobe able pull the tokenIn amount from this contract
        IERC20(params.tokenIn).approve(address(s_izumiRouter), params.amountIn);

        // call swap quoter here to get the minAcquired/minAmountOut tokenOut from the given amountIn of tokenIn
        (uint256 acquire, ) = s_izumiQuoter.swapAmount(params.amountIn, path);
        // swap params
        IIzumiSwap.SwapAmountParams memory swapParams = IIzumiSwap.SwapAmountParams({
            path: path,
            recipient: params.recipient,
            amount: params.amountIn,
            minAcquired: acquire,
            deadline: params.deadline
        });
        // perform the swap
        (, uint256 outAmount) = s_izumiRouter.swapAmount(swapParams);

        if(outAmount <= 0) revert MultihopSwap_ExactInputSwapFailed(params.recipient, params.amountIn, outAmount);
        emit SwapExactInputSuccessfull(params.tokenIn, params.tokenOut, params.amountIn, params.recipient);
        amtOut = outAmount;
    }

    function exactOutputMultihop(ExactOutputMultihopParams memory params) external ValidCaller returns(uint256 amtOut) {
         s_izumiRouter = IIzumiSwap(params.swapRouter);
        //  supported fees for testnet is 400
        bytes memory path = abi.encodePacked(params.tokenOut, uint24(params.fee),  params.poolToken, uint24(params.fee), params.tokenIn);

        // address check
        if(params.tokenIn == address(0) || params.tokenOut == address(0)) revert MultihopSwap_InvalidToken(params.tokenIn, params.tokenOut);
        if(params.recipient == address(0)) revert MultihopSwap_InvalidRecipient(params.recipient);
        if(params.maxAmountIn <= 0) revert MultihopSwap_NotEnoughAmount(params.maxAmountIn);

          // the caller must approve this contract to pull the tokenIn amount
        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.maxAmountIn);
        // approving izumiRouter tobe able pull the tokenIn amount from this contract
        IERC20(params.tokenIn).approve(address(s_izumiRouter), params.maxAmountIn);

        IIzumiSwap.SwapDesireParams memory swapParams = IIzumiSwap.SwapDesireParams({
            path: path,
            recipient: params.recipient,
            desire: params.amountOut,
            maxPayed: params.maxAmountIn,
            deadline: params.deadline
        });

          (, uint256 outAmount) = s_izumiRouter.swapDesire(swapParams);
        if(outAmount <= 0) revert MultihopSwap_ExactInputSwapFailed(params.recipient, params.maxAmountIn, outAmount);
        emit SwapExactOutputSuccessfull(params.tokenIn, params.tokenOut, outAmount, params.recipient);
        amtOut = outAmount;
    }

    // needs to add modifier later
    function updateIzumi(address newRouter, address newQuoter, address newPoolFactory) internal {

        if(newRouter == address(0) || newQuoter == address(0) || newPoolFactory == address(0)) revert("one of the address cannot be zero");
        s_izumiRouter = IIzumiSwap(newRouter);
        s_izumiQuoter = IIzumiQuoter(newQuoter);
        s_izumiFactory = IiZiSwapFactory(newPoolFactory);
    }

    // -------------------------------------------------------------- PUBLIC & EXTERNAL FUNCTIONS ----------------------------------------

}