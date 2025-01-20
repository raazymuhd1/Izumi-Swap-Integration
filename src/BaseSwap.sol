// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IIzumiSwap } from "./interfaces/IIzumiSwap.sol";
import { IIzumiQuoter } from "./interfaces/IIzumiQuoter.sol";
import { IiZiSwapFactory } from "@izumi/contracts/core/interfaces/IiZiSwapFactory.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
    @dev An abstract contract that can be inherits from by other contracts later on.
 */

abstract contract BaseSwap {

    error BaseSwap_InvalidCaller(address caller);
    error BaseSwap_ExactInputSwapFailed(address user, uint256 amountIn, uint256 amountOut);
    error BaseSwap_ExactOutputSwapFailed(address user, uint256 amountIn, uint256 amountOut);
    error BaseSwap_InvalidToken(address tokenIn, address tokenOut);
    error BaseSwap_NotEnoughAmount(uint256 amount);
    error BaseSwap_InvalidRecipient(address rec);

    address private constant EMPTY_POOL = 0x0000000000000000000000000000000000000000;
    IIzumiSwap private s_izumiRouter;
    IIzumiQuoter private s_izumiQuoter;
    IiZiSwapFactory private s_izumiFactory;

    // ---------------------------------------------- EVENTS ---------------------------------------------------------
    event SwapExactInputSuccessfull(address tokenA, address tokenB, uint128 amountIn, address recipient);
    event SwapExactOutputSuccessfull(address tokenA, address tokenB, uint256 amountOut, address recipient);

    constructor(address swapRouter_, address swapQuoter_, address swapPoolFactory_) {
        s_izumiRouter = IIzumiSwap(swapRouter_);
        s_izumiQuoter = IIzumiQuoter(swapQuoter_);
        s_izumiFactory = IiZiSwapFactory(swapPoolFactory_);
    }

    // --------------------------------------------- STRUCTS ---------------------------------------------------------
    // all these params grouped together to avoid stack too deep error from EVM
    struct ExactInputParams {
        address tokenIn;
        address tokenOut;
        uint128 amountIn;
        address recipient;
        address caller; // pass in the inherited contract address
        // supported fee rates:
        // for the MAINNET are 500 (0.05%), 3000 (0.3%), and 10000 (1%), other than that tx will revert;
        // for the TESTNET are 400 (0.04%), 2000 (0.2%) and 10000 (1%)
        uint24 fee;
        uint256 deadline;
    }

    struct ExactOutputParams {
        address tokenIn;
        address tokenOut;
        uint128 amountOut;
        address recipient;
        address caller; // pass in the inherited contract address
        // supported fee rates:
        // for the MAINNET are 500 (0.05%), 3000 (0.3%), and 10000 (1%), other than that tx will revert;
        // for the TESTNET are 400 (0.04%), 2000 (0.2%) and 10000 (1%)
        uint24 fee;
        uint256 deadline;
    }

    struct PoolCheckParamsExactInput {
        address tokenIn;
        address tokenOut; 
        uint24 fee;
        uint256 amountIn; 
        uint256 minAmtOut;
    }

    struct PoolCheckParamsExactOutput {
        address tokenIn;
        address tokenOut; 
        uint24 fee;
        uint256 amountOut; 
        uint256 maxAmtIn;
    }

    // --------------------------------------------MODIFIERS-------------------------------------------------------
    modifier ValidCaller() {
        // using IF instead of REQUIRE for gas opt, REQUIRE much expensive than IF
        if(msg.sender == address(0)) revert BaseSwap_InvalidCaller(msg.sender);
        _;
    }

     // --------------------------------------------INTERNAL & PRIVATE FUNCTIONS -------------------------------------------------------

    /**
        @dev check if the pool exist or not, if pool not exist the swap will fail
     */
     function _poolExistsExactInput(PoolCheckParamsExactInput memory poolParams) internal view {
         address poolAddr = s_izumiFactory.pool(poolParams.tokenOut, poolParams.tokenIn, poolParams.fee);
         if(poolAddr == EMPTY_POOL) revert("pool not exists");
         uint256 poolTokenBBal = IERC20(poolParams.tokenOut).balanceOf(poolAddr);
         if(poolTokenBBal <= poolParams.minAmtOut) revert("pool tokens liquidity is less than the expected token amount");
     }

    /**
        @dev check if the pool exist or not, if pool not exist the swap will fail
     */
     function _poolExistsExactOutput(PoolCheckParamsExactOutput memory poolParams) internal view {
         address poolAddr = s_izumiFactory.pool(poolParams.tokenIn, poolParams.tokenOut, poolParams.fee);
         if(poolAddr == EMPTY_POOL) revert("pool not exists");
        uint256 poolTokenBBal = IERC20(poolParams.tokenOut).balanceOf(poolAddr);
        if(poolTokenBBal <= poolParams.amountOut) revert("pool tokens liquidity is less than the expected token amount");
     }

    /**
        @notice uses swapDesire/swapAmount function from izumiFinance to make a multihop
        @dev IMPORTANT! - make sure the pool exist and has enough liq
        @param params - see @ExactInputMultihopParams struct for params
        @return amtOut - an amount user gets after swapping
     */
    function exactInput(ExactInputParams memory params) internal ValidCaller returns(uint256 amtOut) {
        // swap path in abi.encoded bytes
        bytes memory path = abi.encodePacked(params.tokenIn, uint24(params.fee), params.tokenOut);

        // address check
        if(params.tokenIn == address(0) || params.tokenOut == address(0)) revert BaseSwap_InvalidToken(params.tokenIn, params.tokenOut);
        if(params.recipient == address(0)) revert BaseSwap_InvalidRecipient(params.recipient);
        if(params.amountIn <= 0) revert BaseSwap_NotEnoughAmount(params.amountIn);

        // the caller must approve this contract to pull the tokenIn amount
        IERC20(params.tokenIn).transferFrom(params.caller, address(this), params.amountIn);
        // approving izumiRouter tobe able pull the tokenIn amount from this contract
        IERC20(params.tokenIn).approve(address(s_izumiRouter), params.amountIn);

        // call swap quoter here to get the minAcquired/minAmountOut tokenOut from the given amountIn of tokenIn
        (uint256 acquire, ) = s_izumiQuoter.swapAmount(params.amountIn, path);
        // swap params
        IIzumiSwap.SwapAmountParams memory swapParams = IIzumiSwap.SwapAmountParams({
            path: path,
            recipient: params.recipient,
            amount: params.amountIn,
            minAcquired: acquire, // minAmountOut (minimum amount of tokenOut user would gets from the pool)
            deadline: params.deadline
        });
        // pool checking, check if the pool existed or not
        _poolExistsExactInput(PoolCheckParamsExactInput({tokenIn: params.tokenIn, tokenOut: params.tokenOut, fee: params.fee, amountIn: params.amountIn, minAmtOut: acquire}));
        // perform the swap / calling exactInput swap
        (, uint256 outAmount) = s_izumiRouter.swapAmount(swapParams);

        if(outAmount <= 0) revert BaseSwap_ExactInputSwapFailed(params.recipient, params.amountIn, outAmount);
        emit SwapExactInputSuccessfull(params.tokenIn, params.tokenOut, params.amountIn, params.recipient);
        amtOut = outAmount;
    }


     /**
       @dev call this function for exactOutput multi-hop swap, for params see @ExactOutputMultihopParams struct
       @return amtOut - an amount user gets after swapped
      */
    function exactOutput(ExactOutputParams memory params) internal ValidCaller returns(uint256 amtOut) {
        //  supported fees for testnet is 400
        // swap path for exactOutput in reverse order  
        bytes memory path = abi.encodePacked(params.tokenOut, uint24(params.fee), params.tokenIn);
        // address check
        if(params.tokenIn == address(0) || params.tokenOut == address(0)) revert BaseSwap_InvalidToken(params.tokenIn, params.tokenOut);
        if(params.recipient == address(0)) revert BaseSwap_InvalidRecipient(params.recipient);
        if(params.amountOut <= 0) revert("amount out should be more than 0");

        // quoting the swap, before actually calling swap
        (uint256 cost, ) = s_izumiQuoter.swapDesire(params.amountOut, path);
          // the caller must approve this contract to pull the tokenIn amount, (cost = maxAmountIn)
        IERC20(params.tokenIn).transferFrom(params.caller, address(this), cost);
        // approving izumiRouter tobe able pull the tokenIn amount from this contract
        IERC20(params.tokenIn).approve(address(s_izumiRouter), cost);

        IIzumiSwap.SwapDesireParams memory swapParams = IIzumiSwap.SwapDesireParams({
            path: path,
            recipient: params.recipient,
            desire: params.amountOut, // amountOut
            maxPayed: cost, // cost = maxAmountIn
            deadline: params.deadline
        });
        _poolExistsExactOutput(PoolCheckParamsExactOutput({ tokenIn: params.tokenIn, tokenOut: params.tokenOut, fee: params.fee, amountOut: params.amountOut, maxAmtIn: cost }));
        // calling exactOutput swap
        (uint256 maxAmountIn, uint256 outAmount) = s_izumiRouter.swapDesire(swapParams);
        if(outAmount <= 0) revert BaseSwap_ExactInputSwapFailed(params.recipient, cost, outAmount);
        emit SwapExactOutputSuccessfull(params.tokenIn, params.tokenOut, outAmount, params.recipient);
        amtOut = outAmount;
    }

    /**
        @dev inherited contract can update the izumi router, quoter, and factory addresses using this function
     */
    function updateIzumi(address newRouter, address newQuoter, address newPoolFactory) internal ValidCaller returns(address, address, address) {
        if(newRouter == address(0) || newQuoter == address(0) || newPoolFactory == address(0)) revert("one of the address cannot be zero");
        s_izumiRouter = IIzumiSwap(newRouter);
        s_izumiQuoter = IIzumiQuoter(newQuoter);
        s_izumiFactory = IiZiSwapFactory(newPoolFactory);

        return (address(s_izumiRouter), address(s_izumiQuoter), address(s_izumiFactory));
    }

    // -------------------------------------------------------------- PUBLIC & EXTERNAL FUNCTIONS ----------------------------------------

    /**
      @dev getting an address of this contract, needed by its child
     */
    function _getContractAddress() internal returns(address) {
        return address(this);
    }

}