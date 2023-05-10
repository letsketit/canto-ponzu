// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface PonzuPalace {
  function ponzu() external returns (address);

  function cantoe() external payable returns (address);

  function esketit() external returns (address);

  function liquidity() external returns (address);

  function ponzuSwap(
    uint amountIn,
    uint amountOutMin,
    address tokenFrom,
    address tokenTo,
    bool stable,
    address to
  ) external returns (uint[] memory amounts);

  function isPonzuReady() external view returns (bool);
}
