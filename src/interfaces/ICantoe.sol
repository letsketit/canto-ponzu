// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ICANTOE {
  function deposit() external payable;

  function withdraw(uint wad) external;
}
