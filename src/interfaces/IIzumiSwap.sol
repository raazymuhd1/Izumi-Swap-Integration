// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
    @dev an interface for interacting with @IzumiFinance swap router
 */

interface IIzumiSwap {
    
        // params for exactInput
       struct SwapAmountParams {
        bytes path;
        address recipient;
        // uint256 deadline;
        uint128 amount;
        uint256 minAcquired;

        uint256 deadline;
    }

      // params for exactOutput
      struct SwapDesireParams {
        bytes path;
        address recipient;
        uint128 desire;
        uint256 maxPayed;

        uint256 deadline;
    }

      function swapDesire(SwapDesireParams calldata params)
        external
        payable
        returns (uint256 cost, uint256 acquire);

     function swapAmount(SwapAmountParams calldata params)
        external
        payable
        returns (uint256 cost, uint256 acquire);

}