// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface Turnstile {
  function balances(uint256) external view returns (uint256);

  function register(address) external returns (uint256);

  function assign(uint256) external returns (uint256);

  function getTokenId(address _smartContract) external view returns (uint256);

  function withdraw(
    uint256 _tokenId,
    address payable _recipient,
    uint256 _amount
  ) external returns (uint256);
}
