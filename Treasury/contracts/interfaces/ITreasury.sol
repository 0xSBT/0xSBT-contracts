// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface ITreasury {
  struct Withdraw {
    address token;
    uint256 amount;
    uint256 voteId;
    bool withdrawn;
  }

  function withdrawFund(
    address token,
    address receiver,
    uint256 amount
  ) external;

  function swapTokenUsingPangea(
    address inToken,
    address outToken,
    uint256 amount
  ) external;

  function swapTokenUsingKlayswap(
    address inToken,
    address outToken,
    uint256 amount
  ) external;

  function addLiquidityInKlayswap(address tokenA, address tokenB) external;

  function claimRewardAndSwap(address token) external;

  function removeLiquidityAndZap(address pool, address tokenToZap) external;
}
