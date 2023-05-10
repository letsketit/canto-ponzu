// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface BaseFactory {
  function createPair(
    address tokenA,
    address tokenB,
    bool stable
  ) external returns (address pair);
}
