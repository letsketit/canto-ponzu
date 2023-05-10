// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {TurnstileAware} from "./TurnstileAware.sol";
import {ICANTOE} from "./interfaces/ICantoe.sol";
import {PonzuRewards} from "./PonzuRewards.sol";
import {PonzuPalace} from "./interfaces/IPonzuPalace.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

//
//    ||====================================================================||
//    ||//$\\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\//$\\||
//    ||(100)==================| FEDERAL RESERVE NOTE |================(100)||
//    ||\\$//        ~         '------========--------'                \\$//||
//    ||<< /        /$\              // ____ \\                         \ >>||
//    ||>>|  12    //L\\            // ///..) \\         L38036133B   12 |<<||
//    ||<<|        \\ //           || <||  >\  ||                        |>>||
//    ||>>|         \$/            ||  $$ --/  ||        One Hundred     |<<||
// ||====================================================================||>||
// ||//$\\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\//$\\||<||
// ||(100)==================| FEDERAL RESERVE NOTE |================(100)||>||
// ||\\$//        ~         '------========--------'                \\$//||\||
// ||<< /        /$\              // ____ \\                         \ >>||)||
// ||>>|  12    //L\\            // ///..) \\         L38036133B   12 |<<||/||
// ||<<|        \\ //           || <||  >\  ||                        |>>||=||
// ||>>|         \$/            ||  $$ --/  ||        One Hundred     |<<||
// ||<<|      L38036133B        *\\  |\_/  //* series                 |>>||
// ||>>|  12                     *\\/___\_//*   1989                  |<<||
// ||<<\      Treasurer     ______/Franklin\________     Secretary 12 />>||
// ||//$\                 ~|UNITED STATES OF AMERICA|~               /$\\||
// ||(100)===================  ONE HUNDRED DOLLARS =================(100)||
// ||\\$//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\$//||
// ||====================================================================||
//
// BLUR BLUR BLUR BLUR BLUR BLUR BLUR BLUR BLUR BLUR BLUR BLUR BLUR BLUR BLUR
//
contract PonzuRewardsManager is Owned, TurnstileAware {
  struct PonzuPour {
    uint256 marinating;
    uint256 liquidity;
  }

  uint256 private ponzuRewardsDuartion = 86400;
  uint256 private ponzuDenominator = 10_000;

  // Rewards Tracking
  mapping(address => address) public getRewardsContract;
  mapping(address => uint256) public getTokensClaimed;
  mapping(uint256 => bool) public hasDistributedForDay;

  // Mainnet
  address public note = 0x4e71A2E537B7f9D9413D3991D37958c0b5e1e503;
  address public wcanto = 0x826551890Dc65655a0Aceca109aB11AbDbD7a07B;

  // Testnet
  // address public note = 0x03F734Bd9847575fDbE9bEaDDf9C166F880B5E5f;
  // address public wcanto = 0x04a72466De69109889Db059Cb1A4460Ca0648d9D;

  // Glorious Ponzu
  PonzuPour public pour;
  PonzuPalace public palace;
  uint256 public miningDistributionEnd;
  uint256 public turnstileId;
  uint256 public startTime;
  bytes32 public whitelistHash;

  address public ponzu;
  address public esketit;
  address payable public cantoe;
  address public liquidity;

  // Statistics
  uint256 public cantoeDistributed = 0;
  uint256 public ponzuDistributed = 0;
  uint256 public ponzuClaimed = 0;
  uint256 public claimComplete = 0;
  uint256 public airdropAmount = 0;

  constructor(
    address ponzuPalace,
    uint256 _turnstileId,
    bytes32 claimHash
  ) Owned(msg.sender) {
    turnstileId = _turnstileId;
    turnstile.assign(turnstileId);
    whitelistHash = claimHash;
    pour = PonzuPour(6_500, 3_500);
    startTime = block.timestamp;
    miningDistributionEnd = block.timestamp + 365 days;
    palace = PonzuPalace(ponzuPalace);
  }

  function setupEsketitRewards() external onlyOwner returns (address) {
    require(getRewardsContract[esketit] == address(0));
    ponzu = palace.ponzu();
    esketit = palace.esketit();
    cantoe = payable(palace.cantoe());
    PonzuRewards esketitRewards = new PonzuRewards(
      address(this),
      esketit,
      turnstileId
    );
    getRewardsContract[esketit] = address(esketitRewards);
    esketitRewards.addReward(ponzu, address(this), ponzuRewardsDuartion);
    esketitRewards.addReward(cantoe, address(this), ponzuRewardsDuartion);
    return address(esketitRewards);
  }

  function setupLiquidityRewards() external onlyOwner returns (address) {
    require(getRewardsContract[liquidity] == address(0));
    liquidity = palace.liquidity();
    PonzuRewards liquidityRewards = new PonzuRewards(
      address(this),
      liquidity,
      turnstileId
    );
    liquidityRewards.addReward(ponzu, address(this), ponzuRewardsDuartion);
    liquidityRewards.addReward(cantoe, address(this), ponzuRewardsDuartion);
    getRewardsContract[liquidity] = address(liquidityRewards);
    return address(liquidityRewards);
  }

  function claimPonzu(uint256 amount, bytes32[] calldata proof) external {
    require(getTokensClaimed[msg.sender] == 0, "claimed");
    if (claimComplete == 0) {
      claimComplete = block.timestamp + 7 days;
      airdropAmount =
        (888_888_888_888 * 10 ** IERC20(palace.ponzu()).decimals() * 2) /
        10;
    }
    require(block.timestamp < claimComplete, "complete");
    require(ponzuClaimed < airdropAmount, "complete");
    bytes32 leaf = keccak256(
      bytes.concat(keccak256(abi.encode(msg.sender, amount)))
    );
    require(MerkleProof.verify(proof, whitelistHash, leaf), "!valid");
    uint256 claimAmount = airdropAmount - ponzuClaimed > amount
      ? amount
      : airdropAmount - ponzuClaimed;
    ponzuClaimed += claimAmount;
    getTokensClaimed[msg.sender] += claimAmount;
    IERC20(ponzu).transfer(msg.sender, claimAmount);
    poke();
  }

  function poke() public {
    require(ponzu != address(0), "!ready");
    uint256 claimableCanto = pendingCanto(turnstileId);
    if (claimableCanto > 0) {
      turnstile.withdraw(turnstileId, payable(this), pendingCanto(turnstileId));
    }

    address esketitRewardsAddr = getRewardsContract[esketit];
    address liquidityRewardsAddr = getRewardsContract[liquidity];

    if (
      esketitRewardsAddr == address(0) || liquidityRewardsAddr == address(0)
    ) {
      return;
    }

    PonzuRewards esketitRewards = PonzuRewards(esketitRewardsAddr);
    PonzuRewards liquidityRewards = PonzuRewards(liquidityRewardsAddr);

    uint256 cantoBalance = address(this).balance;
    if (cantoBalance > 0) {
      ICANTOE(cantoe).deposit{value: cantoBalance}();
    }

    // Ponzu Liquidity Mining
    bool distributeMiningRewards = block.timestamp < miningDistributionEnd;

    uint256 stakingPonzu;
    uint256 liquidityPonzu;
    uint256 distrubtedPonzu;

    if (block.timestamp > claimComplete || ponzuClaimed == airdropAmount) {
      distrubtedPonzu = IERC20(ponzu).balanceOf(address(this));
    } else {
      distrubtedPonzu =
        IERC20(ponzu).balanceOf(address(this)) -
        (airdropAmount - ponzuClaimed);
    }

    if (distributeMiningRewards) {
      uint256 dayId = (block.timestamp - startTime) / ponzuRewardsDuartion;

      if (hasDistributedForDay[dayId]) {
        distrubtedPonzu = 0;
      } else {
        uint256 timeRemaining = miningDistributionEnd - block.timestamp;
        uint256 timeSlice = timeRemaining / ponzuRewardsDuartion + 1;
        distrubtedPonzu = distrubtedPonzu / timeSlice;
        hasDistributedForDay[dayId] = true;
      }
    }

    stakingPonzu = (distrubtedPonzu * pour.marinating) / ponzuDenominator;
    ponzuDistributed += stakingPonzu;
    liquidityPonzu = (distrubtedPonzu * pour.liquidity) / ponzuDenominator;
    ponzuDistributed += liquidityPonzu;

    uint256 distributedCantoe = IERC20(cantoe).balanceOf(address(this));
    uint256 stakingCantoe = (distributedCantoe * pour.marinating) /
      ponzuDenominator;
    cantoeDistributed += stakingCantoe;
    uint256 liquidityCantoe = (distributedCantoe * pour.liquidity) /
      ponzuDenominator;
    cantoeDistributed += liquidityCantoe;

    // Distribute Staking Rewards
    IERC20(ponzu).approve(address(esketitRewards), stakingPonzu);
    IERC20(cantoe).approve(address(esketitRewards), stakingCantoe);
    esketitRewards.notifyRewardAmount(ponzu, stakingPonzu);
    esketitRewards.notifyRewardAmount(cantoe, stakingCantoe);
    IERC20(ponzu).approve(address(esketitRewards), 0);
    IERC20(cantoe).approve(address(esketitRewards), 0);

    // Distribute Liquidity Rewards
    IERC20(ponzu).approve(address(liquidityRewards), liquidityPonzu);
    IERC20(cantoe).approve(address(liquidityRewards), liquidityCantoe);
    liquidityRewards.notifyRewardAmount(ponzu, liquidityPonzu);
    liquidityRewards.notifyRewardAmount(cantoe, liquidityCantoe);
    IERC20(ponzu).approve(address(liquidityRewards), 0);
    IERC20(cantoe).approve(address(liquidityRewards), 0);
  }

  function dumpNoteIfRequired() public {
    uint256 noteBalance = IERC20(note).balanceOf(address(this));
    if (!palace.isPonzuReady() || noteBalance == 0) {
      return;
    }

    IERC20(note).approve(address(palace), noteBalance);
    uint[] memory amounts = palace.ponzuSwap(
      noteBalance,
      0,
      note,
      wcanto,
      false,
      address(this)
    );
    IERC20(note).approve(address(palace), 0);

    ICANTOE(payable(wcanto)).withdraw(amounts[amounts.length - 1]);
  }

  receive() external payable {
    ICANTOE(cantoe).deposit{value: msg.value}();
  }

  fallback() external payable {
    ICANTOE(cantoe).deposit{value: msg.value}();
  }
}
