// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {TurnstileAware} from "./TurnstileAware.sol";
import {Ponzu} from "./Ponzu.sol";
import {CANTOE} from "./Cantoe.sol";
import {LunchToken} from "./LunchToken.sol";
import {BaseFactory} from "./interfaces/IBaseFactory.sol";
import {BaseRouter} from "./interfaces/IBaseRouter.sol";
import {IPonzuRewardsManager} from "./interfaces/IPonzuRewardsManager.sol";

//
//                   ^
//                  / \
//             ^   _|.|_   ^
//           _|I|  |I .|  |.|_
//           \II||~~| |~~||  /
//            ~\~|~~~~~~~|~/~
//              \|II I ..|/
//         /\    |II.    |    /\
//        /  \  _|III .  |_  /  \
//        |-~| /(|I.I I  |)\ |~-|
//      _/(I | +-----------+ |. )\_
//      \~-----/____-~-____\-----~/
//       |I.III|  /(===)\  |  .. |
//       /~~~-----_________---~~~\
//      `##########!\-#####%!!!!!| |\
//     _/###########!!\~~-_##%!!!\_/|
//     \##############!!!!!/~~-_%!!!!\
//      ~)#################!!!!!/~~--\_
//   __ /#####################%%!!!!/ /
//   \,~\-_____##############%%%!!!!\/
//   /!!!!\ \ \~-_###########%%%!!!!\
//  /#####!!!!!!!\~-_#######%%%!!!!!!\_
// /#############!!!\#########%%%!!!!!!\
//
//      Welcome to the Palace, Kid
//
contract PonzuPalace is Owned, TurnstileAware {
  uint256 private ponzuDenominator = 10_000;

  bool public inSwap;
  modifier handleSwap() {
    inSwap = true;
    _;
    inSwap = false;
  }

  // Mainnet
  address public factory = 0xE387067f12561e579C5f7d4294f51867E0c1cFba;
  address public router = 0xa252eEE9BDe830Ca4793F054B506587027825a8e;
  address public note = 0x4e71A2E537B7f9D9413D3991D37958c0b5e1e503;
  address public wcanto = 0x826551890Dc65655a0Aceca109aB11AbDbD7a07B;

  // Testnet
  // address public factory = 0x760a17e00173339907505B38F95755d28810570C;
  // address public router = 0x463e7d4DF8fE5fb42D024cb57c77b76e6e74417a;
  // address public note = 0x03F734Bd9847575fDbE9bEaDDf9C166F880B5E5f;
  // address public wcanto = 0x04a72466De69109889Db059Cb1A4460Ca0648d9D;

  // Rewards Tracking
  mapping(address => bool) public isPonzuFree;
  mapping(address => bool) public isPonzuTransporter;

  // Glorious Ponzu
  address public ponzu;
  address payable public cantoe;
  address public esketit;
  address public liquidity;
  address public rewardsManager;

  uint256 public ponzuPrice;
  uint256 public turnstileId;
  uint256 public liquidityAdded = 0;

  bool public isPonzuReady = false;

  constructor() Owned(msg.sender) {
    turnstileId = turnstile.register(tx.origin);
  }

  // Admin Functionality
  function pourPonzu() external onlyOwner {
    require(ponzu == address(0), "Ponzu already poured!");
    require(rewardsManager != address(0), "!rewardsManager");
    ponzu = address(new Ponzu(address(this), turnstileId));
    cantoe = payable(new CANTOE(rewardsManager, turnstileId));
    esketit = address(new LunchToken(address(this), turnstileId));
    isPonzuTransporter[esketit] = true;
    isPonzuTransporter[address(this)] = true;

    Ponzu(ponzu).mint(
      address(this),
      888_888_888_888 * 10 ** Ponzu(ponzu).decimals()
    );
    isPonzuFree[address(this)] = true;
    isPonzuFree[msg.sender] = true;
    ponzuPrice = 444;

    address esketitRewards = IPonzuRewardsManager(rewardsManager)
      .setupEsketitRewards();
    isPonzuTransporter[esketitRewards] = true;
  }

  function pourPonzuPool(
    uint256 cantoBaseLiquidity
  ) external payable onlyOwner {
    require(cantoBaseLiquidity != 0);
    uint256 ponzuBaseLiquidity = 444_444_444_444 * 1e12;
    require(msg.value == cantoBaseLiquidity, "!canto");
    liquidity = BaseFactory(factory).createPair(ponzu, cantoe, false);

    CANTOE(cantoe).deposit{value: cantoBaseLiquidity}();
    this.providerPonzuLiquidity(
      ponzuBaseLiquidity,
      cantoBaseLiquidity,
      ponzuBaseLiquidity,
      cantoBaseLiquidity
    );

    address liquidityRewards = IPonzuRewardsManager(rewardsManager)
      .setupLiquidityRewards();
    isPonzuTransporter[liquidityRewards] = true;
  }

  function registerRewardsManager(address _rewardsManager) external onlyOwner {
    require(Owned(_rewardsManager).owner() == address(this));
    rewardsManager = _rewardsManager;
  }

  function markItReady() external onlyOwner {
    require(Ponzu(ponzu).balanceOf(address(this)) > 0, "!ponzu");
    require(liquidity != address(0), "!liquidity");
    isPonzuReady = true;
    IERC20(ponzu).transfer(
      rewardsManager,
      (888_888_888_888 * 10 ** Ponzu(ponzu).decimals() * 5) / 10
    );
  }

  function setPonzuFree(address target, bool ponzuFree) external onlyOwner {
    isPonzuFree[target] = ponzuFree;
  }

  function setPonzuTransporter(
    address target,
    bool isTransporter
  ) external onlyOwner {
    isPonzuTransporter[target] = isTransporter;
  }

  // Ponzu Functionality

  function ponzuSwap(
    uint amountIn,
    uint amountOutMin,
    address tokenFrom,
    address tokenTo,
    bool stable
  ) public returns (uint[] memory amounts) {
    require(isPonzuReady, "!ready");
    if (msg.sender != address(this)) {
      IERC20(tokenFrom).transferFrom(msg.sender, payable(this), amountIn);
    }

    Ponzu(ponzu).startPonzuTransfer();
    IERC20(tokenFrom).approve(router, amountIn);
    amounts = BaseRouter(router).swapExactTokensForTokensSimple(
      amountIn,
      amountOutMin,
      tokenFrom,
      tokenTo,
      stable,
      address(this),
      block.timestamp
    );
    IERC20(tokenFrom).approve(router, 0);
    Ponzu(ponzu).finishPonzuTransfer();

    uint256 trollToll = 0;
    if (!inSwap) {
      bool shouldPayFee = !isPonzuFree[msg.sender];
      trollToll = shouldPayFee
        ? (amounts[amounts.length - 1] * ponzuPrice) / ponzuDenominator
        : 0;

      if (trollToll > 0) {
        uint256 liquidityAmount = (trollToll * 1_000) / ponzuDenominator;
        IERC20(tokenTo).transfer(rewardsManager, trollToll - liquidityAmount);
        addPonzuLiquidity(tokenTo, liquidityAmount);
      }
    }

    uint256 outputAmount = amounts[amounts.length - 1] - trollToll;
    amounts[amounts.length - 1] = outputAmount;
    IERC20(tokenTo).transfer(msg.sender, outputAmount);

    IPonzuRewardsManager(rewardsManager).poke();
  }

  function providerPonzuLiquidity(
    uint256 ponzuAmount,
    uint256 cantoeAmount,
    uint256 minPonzuAmount,
    uint256 minCantoeAmount
  ) public {
    if (msg.sender != address(this)) {
      require(
        Ponzu(ponzu).transferFrom(msg.sender, address(this), ponzuAmount),
        "!ponzu"
      );
      require(
        CANTOE(cantoe).transferFrom(msg.sender, address(this), cantoeAmount),
        "!cantoe"
      );
    }

    Ponzu(ponzu).startPonzuTransfer();
    IERC20(ponzu).approve(router, ponzuAmount);
    IERC20(cantoe).approve(router, cantoeAmount);
    (, , uint amountOut) = BaseRouter(router).addLiquidity(
      ponzu,
      cantoe,
      false,
      ponzuAmount,
      cantoeAmount,
      minPonzuAmount,
      minCantoeAmount,
      address(this),
      block.timestamp
    );
    IERC20(ponzu).approve(router, 0);
    IERC20(cantoe).approve(router, 0);
    Ponzu(ponzu).finishPonzuTransfer();

    if (msg.sender != address(this)) {
      IERC20(liquidity).transfer(msg.sender, amountOut);
    }

    IPonzuRewardsManager(rewardsManager).poke();
  }

  function addPonzuLiquidity(
    address tokenFrom,
    uint256 amount
  ) internal handleSwap {
    if (tokenFrom != cantoe && tokenFrom != ponzu) {
      return;
    }

    address tokenTo = tokenFrom == cantoe ? ponzu : cantoe;
    uint[] memory amounts = this.ponzuSwap(
      amount / 2,
      0,
      tokenFrom,
      tokenTo,
      false
    );

    uint256 ponzuAmount = tokenFrom == cantoe
      ? amounts[amounts.length - 1]
      : amount / 2;
    uint256 cantoAmount = tokenFrom == cantoe
      ? amount / 2
      : amounts[amounts.length - 1];
    uint256 beforeBalance = IERC20(liquidity).balanceOf(address(this));
    this.providerPonzuLiquidity(ponzuAmount, cantoAmount, 0, 0);
    liquidityAdded +=
      IERC20(liquidity).balanceOf(address(this)) -
      beforeBalance;
  }

  receive() external payable {
    CANTOE(cantoe).deposit{value: msg.value}();
  }

  fallback() external payable {
    CANTOE(cantoe).deposit{value: msg.value}();
  }
}
