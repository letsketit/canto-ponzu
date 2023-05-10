// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {TurnstileAware} from "./TurnstileAware.sol";
import {PonzuPalace} from "./PonzuPalace.sol";
import {IPonzuRewardsManager} from "./interfaces/IPonzuRewardsManager.sol";

//                        *
//                                   *
//      *                                             *
//                                           *
//                *
//                              *
//                                                        *
//     *
//                                              *
//         *
//                       *             *
//                                                 *
//  *                                                               *
//           *
//                           (             )
//                   )      (*)           (*)      (
//          *       (*)      |             |      (*)
//                   |      |~|           |~|      |          *
//                  |~|     | |           | |     |~|
//                  | |     | |           | |     | |
//                 ,| |a@@@@| |@@@@@@@@@@@| |@@@@a| |.
//            .,a@@@| |@@@@@| |@@@@@@@@@@@| |@@@@@| |@@@@a,.
//          ,a@@@@@@| |@@@@@@@@@@@@.@@@@@@@@@@@@@@| |@@@@@@@a,
//         a@@@@@@@@@@@@@@@@@@@@@' . `@@@@@@@@@@@@@@@@@@@@@@@@a
//         ;`@@@@@@@@@@@@@@@@@@'   .   `@@@@@@@@@@@@@@@@@@@@@';
//         ;@@@`@@@@@@@@@@@@@'     .     `@@@@@@@@@@@@@@@@'@@@;
//         ;@@@;,.aaaaaaaaaa       .       aaaaa,,aaaaaaa,;@@@;
//         ;;@;;;;@@@@@@@@;@      @.@      ;@@@;;;@@@@@@;;;;@@;
//         ;;;;;;;@@@@;@@;;@    @@ . @@    ;;@;;;;@@;@@@;;;;;;;
//         ;;;;;;;;@@;;;;;;;  @@   .   @@  ;;;;;;;;;;;@@;;;;@;;
//         ;;;;;;;;;;;;;;;;;@@     .     @@;;;;;;;;;;;;;;;;@@a;
//     ,%%%;;;;;;;;@;;;;;;;;       .       ;;;;;;;;;;;;;;;;@@;;%%%,
//  .%%%%%%;;;;;;;a@;;;;;;;;     ,%%%,     ;;;;;;;;;;;;;;;;;;;;%%%%%%,
// .%%%%%%%;;;;;;;@@;;;;;;;;   ,%%%%%%%,   ;;;;;;;;;;;;;;;;;;;;%%%%%%%,
// %%%%%%%%`;;;;;;;;;;;;;;;;  %%%%%%%%%%%  ;;;;;;;;;;;;;;;;;;;'%%%%%%%%
// %%%%%%%%%%%%`;;;;;;;;;;;;,%%%%%%%%%%%%%,;;;;;;;;;;;;;;;'%%%%%%%%%%%%
// `%%%%%%%%%%%%%%%%%,,,,,,,%%%%%%%%%%%%%%%,,,,,,,%%%%%%%%%%%%%%%%%%%%'
//   `%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
//       `%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
//              """"""""""""""`,,,,,,,,,'"""""""""""""""""
//                             `%%%%%%%'
//                              `%%%%%'
//                                %%%
//                               %%%%%
//                            .,%%%%%%%,.
//                       ,%%%%%%%%%%%%%%%%%%%,
//           ---------------------------------------------
//                        The Cake is a Lie
//
contract Ponzu is ERC20, Owned, TurnstileAware {
  bool public isPonzuTransferring = false;

  PonzuPalace public ponzuPalace;
  bool public canMintTokens = true;

  constructor(
    address _ponzuPalace,
    uint256 turnstileId
  ) ERC20("PonzuToken", "PONZU", 12) Owned(msg.sender) {
    ponzuPalace = PonzuPalace(payable(_ponzuPalace));
    turnstile.assign(turnstileId);
  }

  function mint(address to, uint256 amount) external onlyOwner {
    require(canMintTokens);
    _mint(to, amount);
    canMintTokens = false;
  }

  function startPonzuTransfer() external onlyOwner {
    require(!isPonzuTransferring);
    isPonzuTransferring = true;
  }

  function finishPonzuTransfer() external onlyOwner {
    require(isPonzuTransferring);
    isPonzuTransferring = false;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public override returns (bool) {
    require(
      isPonzuTransferring ||
        ponzuPalace.isPonzuTransporter(from) ||
        ponzuPalace.isPonzuTransporter(to),
      "!transporting"
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
