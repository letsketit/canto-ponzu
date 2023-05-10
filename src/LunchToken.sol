// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {TurnstileAware} from "./TurnstileAware.sol";
import {PonzuPalace} from "./PonzuPalace.sol";
import {IPonzuRewardsManager} from "./interfaces/IPonzuRewardsManager.sol";

//        ._               ..
//       /  \            .' |
//       | / \         .' \ |
//       | // \       /  \\ |
//      .| /// `-----' \\\\ |
//    .' .--       --.\\\\   \
//  .'  /             \    \  \
//  |  .  __        ____  \ \ |
//  |  |//        /     `. \  |
//     |/  AMA |    AMA   \ \ |
//     /    VM     AMMV    \ \|`.
//      .-.--     ___   \   \ | |
//     / /   MMMA    .   |   \| |
//    / /   .VMV   -. \  |   |  |
//    |/    .    .   \|  |   |  |
//    ||     `--'     |  \   |  |                .-.
//    ||   .--        | | |  |  |               / |||
//    ||  /      .    | | |     |_____________.'\ |||
//    || /|       \   | | |     |`.`.`.`.`.`.`.`.\ ||
//     |/         |   |   |     |`.`.`.`.`.`.`.`.`.\\
//     /          |    \  |     | \ \ \\ \ \ \ \ \ \\\
//     |   /           |  |     | |  | || | | | | | \\\
//    /   /            |  |   | | |  | || | | | | | |  .
//    |   |               |   | | |  | || | | | | | || |
//    |   | |   |         |   |  ||  | || | | | | |  | `.
//    |   | |   |         |   |  ||  | || | | | | |  |  |
//    |     |  /          |   |  ||  | || | | | |    |  |
//    | /     /               |  || || || | | | |  | |  |
//     /      |  |  |         |  || |  || ||  |  | | |  |
//    /       |  |  |         |  || |  || ||  |  | | |  |
//    |       |  |   |        |  || |  |   |  |  | | |  |
//    |              |      | |  || || |   |     | | |  |
//    |    |         |   |  | |   | || |   |       | |  `.
//    |    |          |  |  | |        |   |        |    |
//   /     |          |  |    |               |  |  | || `.
//   |  |  |  |       |  |    |               |  |   |    |
//   |  |     |       |  |   ||                  |   |    |
//   |  |     |       |  |   ||
// VK  ||     |          |   |
//
//  WOOF WOOF WOOF WOOF WOOF WOOF WOOF WOOF WOOF WOOF WOOF
//                MORE WOOFY THAN WOOFY
//
contract LunchToken is ERC20, Owned, TurnstileAware {
  mapping(address => uint256) public unlockTimes;

  PonzuPalace ponzuPalace;
  IPonzuRewardsManager rewardsManager;
  ERC20 ponzu;

  constructor(
    address _ponzuPalace,
    uint256 turnstileId
  ) ERC20("LunchToken", "ESKETIT", 18) Owned(msg.sender) {
    ponzuPalace = PonzuPalace(payable(_ponzuPalace));
    rewardsManager = IPonzuRewardsManager(ponzuPalace.rewardsManager());
    ponzu = ERC20(ponzuPalace.ponzu());
    turnstile.assign(turnstileId);
  }

  function AAAAAA(address hungryDog, uint256 amount) external returns (bool) {
    require(ponzu.transferFrom(hungryDog, address(this), amount), "!coins");
    _mint(hungryDog, amount);
    unlockTimes[msg.sender] = block.timestamp + 7 days;
    rewardsManager.poke();
    return true;
  }

  function manOhMan(address poorDog, uint256 amount) external returns (bool) {
    require(unlockTimes[msg.sender] < block.timestamp, "!unlocked");
    _burn(poorDog, amount);
    require(ponzu.transfer(poorDog, amount));
    rewardsManager.poke();
    return true;
  }

  // NO TRANSFER BAD DOGGY
  function transfer(address to, uint256 amount) public override returns (bool) {
    require(ponzuPalace.isPonzuTransporter(msg.sender), "!transporting");
    balanceOf[msg.sender] -= amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      balanceOf[to] += amount;
    }

    emit Transfer(msg.sender, to, amount);

    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public override returns (bool) {
    require(
      ponzuPalace.isPonzuTransporter(msg.sender) || msg.sender == owner,
      "!transporter"
    );
    uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

    if (allowed != type(uint256).max)
      allowance[from][msg.sender] = allowed - amount;

    balanceOf[from] -= amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      balanceOf[to] += amount;
    }

    emit Transfer(from, to, amount);

    return true;
  }
}
