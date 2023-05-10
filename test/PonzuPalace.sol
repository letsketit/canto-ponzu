// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Ponzu.sol";
import "../src/PonzuPalace.sol";
import "../src/LunchToken.sol";
import "../src/interfaces/IBaseRouter.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/tokens/ERC721.sol";
import {PonzuRewards} from "../src/PonzuRewards.sol";
import {PonzuRewardsManager} from "../src/PonzuRewardsManager.sol";

contract PonzuPalaceTest is Test {
  address public randomPerson = 0x6ef2b08681C21bCD06e77381Eb7b9bCa2afb2D22;
  address public noteWhale = 0x07379565cD8B0CaE7c60Dc78e7f601b34AF2A21c;
  address public airdropClaimer = 0xe7A4Dd3f2B5a2F0d6c0Cbe42e0176bDd00541851;
  address public wcanto = 0x826551890Dc65655a0Aceca109aB11AbDbD7a07B;

  address public factory = 0xE387067f12561e579C5f7d4294f51867E0c1cFba;
  address public router = 0xa252eEE9BDe830Ca4793F054B506587027825a8e;

  uint256 public maxWCanto = 1_000_000 * 1e18;
  uint256 public cantoBaseLiquidity = 5_000 * 1e18;
  uint256 public ponzuBaseLiquidity = 444_444_444_444 * 1e12;

  PonzuPalace public palace;
  Ponzu public ponzu;
  CANTOE public cantoe;
  LunchToken public esketit;
  PonzuRewardsManager public rewardsManager;

  function setUp() public {
    palace = new PonzuPalace();

    rewardsManager = new PonzuRewardsManager(
      address(palace),
      palace.turnstileId(),
      bytes32(
        0xcd88fd86a2a81828d829ead5f0b0201e27ca41216de6592e81342feca71f8610
      )
    );
    Owned(rewardsManager).transferOwnership(address(palace));
    palace.registerRewardsManager(address(rewardsManager));

    vm.prank(0xFa0A1789742CF47280AAFe8864B200aBc9eFC40F);
    ERC20(wcanto).transfer(address(this), maxWCanto);

    address note = palace.note();
    vm.prank(noteWhale);
    ERC20(note).transfer(address(rewardsManager), 10_000 * 1e18);

    CANTOE(payable(wcanto)).withdraw(maxWCanto);
  }

  function deployPonzu() public {
    palace.pourPonzu();
    ponzu = Ponzu(palace.ponzu());
    cantoe = CANTOE(palace.cantoe());
    esketit = LunchToken(palace.esketit());

    palace.pourPonzuPool{value: cantoBaseLiquidity}(cantoBaseLiquidity);
  }

  function testPostDeploy() public view {
    assert(rewardsManager.whitelistHash() != 0);
    assert(palace.turnstileId() != 0);
    assert(palace.ponzu() == address(0));
  }

  function testPourPonzu() public {
    palace.pourPonzu();
    assert(palace.ponzu() != address(0));
    assert(palace.esketit() != address(0));
    assert(palace.cantoe() != address(0));

    assert(palace.isPonzuTransporter(palace.esketit()));
    assert(palace.isPonzuTransporter(address(palace)));
    assert(palace.ponzuPrice() == 444);
    assert(
      Ponzu(palace.ponzu()).balanceOf(address(palace)) ==
        888_888_888_888 * 10 ** Ponzu(palace.ponzu()).decimals()
    );
  }

  function testFailInfiniteMint() public {
    palace.pourPonzu();
    ponzu.mint(address(this), ponzuBaseLiquidity);
  }

  function testFailMarkItReadyNoPour() public {
    palace.markItReady();
  }

  function testFailMarkItReadyNoLiquidity() public {
    palace.pourPonzu();
    palace.markItReady();
  }

  function testRewardsManagerSetup() public {
    deployPonzu();
    (uint256 marinating, uint256 liquidity) = rewardsManager.pour();
    assert(marinating == 6_500);
    assert(liquidity == 3_500);
  }

  function testPourPool() public {
    deployPonzu();

    assert(palace.liquidity() != address(0));
    assert(rewardsManager.getRewardsContract(palace.liquidity()) != address(0));
    assert(rewardsManager.getRewardsContract(palace.ponzu()) == address(0));
    assert(rewardsManager.getRewardsContract(palace.cantoe()) == address(0));
    assert(rewardsManager.getRewardsContract(palace.esketit()) != address(0));
    assert(
      palace.isPonzuTransporter(
        rewardsManager.getRewardsContract(palace.esketit())
      )
    );
    assert(
      palace.isPonzuTransporter(
        rewardsManager.getRewardsContract(palace.liquidity())
      )
    );
    assert(ERC20(palace.liquidity()).balanceOf(address(palace)) != 0);
  }

  function testTransferPonzu() public {
    deployPonzu();
    palace.markItReady();

    vm.prank(address(rewardsManager));
    ERC20(address(ponzu)).transfer(address(this), ponzuBaseLiquidity / 10);
    assert(ponzu.balanceOf(address(this)) == ponzuBaseLiquidity / 10);
  }

  function testFailSwapNotReady() public {
    deployPonzu();

    vm.prank(address(rewardsManager));
    ERC20(address(ponzu)).transfer(address(this), ponzuBaseLiquidity);

    palace.ponzuSwap(
      ponzuBaseLiquidity,
      0,
      palace.ponzu(),
      palace.cantoe(),
      false
    );
  }

  function testPonzuSwap() public {
    deployPonzu();
    palace.markItReady();

    uint256 swapAmount = ponzuBaseLiquidity / 5;
    vm.prank(address(rewardsManager));
    ERC20(address(ponzu)).transfer(randomPerson, swapAmount);

    vm.prank(randomPerson);
    ERC20(address(ponzu)).approve(address(palace), swapAmount);

    vm.prank(randomPerson);
    uint[] memory amounts = palace.ponzuSwap(
      swapAmount,
      0,
      address(ponzu),
      address(cantoe),
      false
    );
    assert(amounts[amounts.length - 1] > 0);
  }

  function testFailNormalSwap() public {
    deployPonzu();
    palace.markItReady();

    uint256 swapAmount = ponzuBaseLiquidity / 5;
    vm.prank(address(rewardsManager));
    ERC20(address(ponzu)).transfer(randomPerson, swapAmount);

    vm.prank(randomPerson);
    ERC20(address(ponzu)).approve(address(router), swapAmount);

    vm.prank(randomPerson);

    BaseRouter(router).swapExactTokensForTokensSimple(
      swapAmount,
      0,
      address(ponzu),
      address(cantoe),
      false,
      randomPerson,
      block.timestamp + 1000
    );
  }

  function testStakePonzu() public {
    deployPonzu();
    palace.markItReady();

    vm.prank(address(rewardsManager));
    ERC20(address(ponzu)).transfer(address(this), ponzuBaseLiquidity);

    ERC20(ponzu).approve(address(esketit), ponzuBaseLiquidity);
    esketit.AAAAAA(address(this), ponzuBaseLiquidity);
    assert(ERC20(ponzu).balanceOf(address(this)) == 0);
    assert(ERC20(esketit).balanceOf(address(this)) == ponzuBaseLiquidity);
  }

  function testFailTransferEsketit() public {
    deployPonzu();
    palace.markItReady();

    vm.prank(address(rewardsManager));
    ERC20(address(ponzu)).transfer(address(this), ponzuBaseLiquidity);

    ERC20(ponzu).approve(address(esketit), ponzuBaseLiquidity);
    esketit.AAAAAA(address(this), ponzuBaseLiquidity);

    esketit.transfer(randomPerson, ponzuBaseLiquidity);
  }

  function testFailUnstakeEsketitEarly() public {
    deployPonzu();
    palace.markItReady();

    vm.prank(address(rewardsManager));
    ERC20(address(ponzu)).transfer(address(this), ponzuBaseLiquidity);

    ERC20(ponzu).approve(address(esketit), ponzuBaseLiquidity);
    esketit.AAAAAA(address(this), ponzuBaseLiquidity);
    esketit.manOhMan(address(this), ponzuBaseLiquidity);
  }

  function testUnstakeEsketit() public {
    deployPonzu();
    palace.markItReady();

    vm.prank(address(rewardsManager));
    ERC20(address(ponzu)).transfer(address(this), ponzuBaseLiquidity);

    ERC20(ponzu).approve(address(esketit), ponzuBaseLiquidity);
    esketit.AAAAAA(address(this), ponzuBaseLiquidity);

    vm.warp(block.timestamp + 8 days);

    esketit.manOhMan(address(this), ponzuBaseLiquidity);
  }

  function randomSwap(uint256 swapAmount) public {
    if (swapAmount == 0) {
      return;
    }

    vm.startPrank(randomPerson);
    ERC20(address(ponzu)).approve(address(palace), swapAmount);

    palace.ponzuSwap(swapAmount, 0, address(ponzu), address(cantoe), false);

    uint256 newSwapAmount = cantoe.balanceOf(address(randomPerson));
    if (newSwapAmount == 0) {
      return;
    }
    ERC20(address(cantoe)).approve(address(palace), newSwapAmount);

    palace.ponzuSwap(newSwapAmount, 0, address(cantoe), address(ponzu), false);
    vm.stopPrank();
  }

  function testRewardsManagement() public {
    deployPonzu();
    palace.markItReady();

    ERC20(palace.liquidity()).transfer(
      randomPerson,
      ERC20(palace.liquidity()).balanceOf(address(this)) / 5
    );

    vm.warp(block.timestamp + 2 days);

    uint256 swapAmount = ponzuBaseLiquidity / 5;
    vm.prank(address(rewardsManager));
    ERC20(address(ponzu)).transfer(randomPerson, swapAmount);

    for (uint256 i = 0; i < 5; i++) {
      randomSwap(swapAmount);
      swapAmount = ponzu.balanceOf(address(this));
    }

    PonzuRewards liquidityRewards = PonzuRewards(
      rewardsManager.getRewardsContract(palace.liquidity())
    );
    assert(
      liquidityRewards.lastTimeRewardApplicable(address(cantoe)) ==
        block.timestamp
    );
    assert(liquidityRewards.getRewardForDuration(address(cantoe)) > 0);
    assert(
      liquidityRewards.lastTimeRewardApplicable(address(ponzu)) ==
        block.timestamp
    );
    assert(liquidityRewards.getRewardForDuration(address(ponzu)) > 0);

    PonzuRewards eketitRewards = PonzuRewards(
      rewardsManager.getRewardsContract(palace.esketit())
    );
    assert(
      eketitRewards.lastTimeRewardApplicable(address(cantoe)) == block.timestamp
    );
    assert(eketitRewards.getRewardForDuration(address(cantoe)) > 0);
    assert(
      eketitRewards.lastTimeRewardApplicable(address(ponzu)) == block.timestamp
    );
    assert(eketitRewards.getRewardForDuration(address(ponzu)) > 0);

    assert(palace.liquidityAdded() > 0);
    assert(rewardsManager.cantoeDistributed() > 0);
    assert(rewardsManager.ponzuDistributed() > 0);

    vm.prank(address(rewardsManager));
    ERC20(address(ponzu)).transfer(randomPerson, ponzuBaseLiquidity / 5);

    vm.startPrank(randomPerson);
    ERC20(address(ponzu)).approve(
      address(esketit),
      ERC20(address(ponzu)).balanceOf(randomPerson)
    );
    esketit.AAAAAA(randomPerson, ERC20(address(ponzu)).balanceOf(randomPerson));
    ERC20(address(esketit)).approve(
      address(eketitRewards),
      ERC20(address(esketit)).balanceOf(randomPerson)
    );
    eketitRewards.stake(esketit.balanceOf(randomPerson));
    eketitRewards.withdraw(eketitRewards.balanceOf(randomPerson));
    vm.stopPrank();
  }

  function testFailClaimNotReady() public {
    deployPonzu();
    bytes32 e1 = bytes32(
      0xdc62a78f1acbc9613072ce1b6a6ee71ec75cd350bbbe25770972408d1e4dd293
    );
    bytes32 e2 = bytes32(
      0xad057f3614192d23d41f54cdc0e83366c8d28ed3f1244de0c38a1616614e189a
    );
    bytes32[] memory proof = new bytes32[](2);
    proof[0] = e1;
    proof[1] = e2;
    rewardsManager.claimPonzu(10000000000000000000, proof);
  }

  function testClaim() public {
    deployPonzu();
    palace.markItReady();

    vm.startPrank(airdropClaimer);

    bytes32[] memory proof = new bytes32[](17);

    proof[
      0
    ] = 0xa2a54d547f4e26f7378455719c1a633d7713b56993ef04adbad99eb5059506d0;
    proof[
      1
    ] = 0xbe491671d3ccb4c6080731b61fb3db6eb00dd72fa9bd5128a2fb5a8c706e9a7d;
    proof[
      2
    ] = 0x3f76992fedf67cd1495786fbb910fa7ceefa3dc859fbb9d012b3acadc9183201;
    proof[
      3
    ] = 0x78f7a7fca983c2bb6deae15ea659b29f0b933458862c9abe45a6abe3a0908984;
    proof[
      4
    ] = 0x0655a5150ba936dc752580c9de3fa0aad50f51a7f53df97be41f6e11a8f3cffb;
    proof[
      5
    ] = 0xfb0de14b3e68f54bd5b85c96282f5660b7691250b2ca52555e0187cdb2e827ed;
    proof[
      6
    ] = 0xe173c781513d04e835bf316537a7281d427f13f5657a4fc595e53a3b7d386d2a;
    proof[
      7
    ] = 0x7118b759745abe9fd63cf525a7291d0ac54d6dd21befced2a429696447519ed9;
    proof[
      8
    ] = 0xb7b344f8501909e586b03f26fdb846c386a10d0a934d0277c1d31279ce15d493;
    proof[
      9
    ] = 0x9212b271833f975dd1d0467c49daa7f2832dffb607ce4cca582c3665aeeb67e1;
    proof[
      10
    ] = 0x655c90c2fedd8a4c31873061e08f1398189bd3adf647fbcf3e5f68dd17e508c0;
    proof[
      11
    ] = 0x19d397a618998a54d632508035a5f9691cd6c5e71e6bdb98799b6a000cb4fd1d;
    proof[
      12
    ] = 0xe664c86e08e183300b51e20242a80fd45e4a0fa89b00d9e2279a66ae5c6f9d49;
    proof[
      13
    ] = 0x8b236f93968186cdf03f30d3a78cd6a7251be64bf2d41b23eaecc94d7f6d91b6;
    proof[
      14
    ] = 0x9f2dabd6bdd7958f803e9ce9184adad5eafe5bb8ccd0281af61550c158eb7968;
    proof[
      15
    ] = 0xfaf52175b0a9fd53f3a62ce4251dbee7df1735a41426d5231db1e7c9ec619d66;
    proof[
      16
    ] = 0xfeeb1ba2d5c55f95327b383bb58d2b174ebf759e157d981e6dc6dcc48784cfc8;

    rewardsManager.claimPonzu(3343057850972644894648, proof);

    vm.stopPrank();
  }

  receive() external payable {}

  fallback() external payable {}
}
