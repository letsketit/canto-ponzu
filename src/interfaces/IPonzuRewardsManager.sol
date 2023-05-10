// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IPonzuRewardsManager {
  function setupEsketitRewards() external returns (address);

  function setupLiquidityRewards() external returns (address);

  function poke() external;

  function dumpNoteIfRequired() external;
}
