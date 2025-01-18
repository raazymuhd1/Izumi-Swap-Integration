// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
  @dev this quoter needed to query the amount user needs to pay for swapping, and the amount they will get
 */

interface IIzumiQuoter {
     function swapAmount(
        uint128 amount,
        bytes memory path
    ) external returns (uint256 acquire, int24[] memory pointAfterList);

    function swapDesire(
        uint128 desire,
        bytes memory path
    ) external returns (uint256 cost, int24[] memory pointAfterList);
}