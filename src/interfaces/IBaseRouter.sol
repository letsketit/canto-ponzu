// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface BaseRouter {
  function addLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);

  function swapExactTokensForTokensSimple(
    uint amountIn,
    uint amountOutMin,
    address tokenFrom,
    address tokenTo,
    bool stable,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function pairFor(
    address tokenA,
    address tokenB,
    bool stable
  ) external view returns (address pair);

  function getAmountOut(
    uint amountIn,
    address tokenIn,
    address tokenOut
  ) external view returns (uint amount, bool stable);

  function removeLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);

  function quoteAddLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint amountADesired,
    uint amountBDesired
  ) external view returns (uint amountA, uint amountB, uint liquidity);

  function getReserves(
    address tokenA,
    address tokenB,
    bool stable
  ) external view returns (uint reserveA, uint reserveB);
}
