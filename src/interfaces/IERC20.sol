// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function allowance(
    address owner,
    address spender
  ) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transfer(
    address _to,
    uint256 _value
  ) external returns (bool success);

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) external returns (bool success);

  function decimals() external view returns (uint8);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  // EIP 2612
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}
