// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/PonzuPalace.sol";
import {PonzuRewardsManager} from "../src/PonzuRewardsManager.sol";
import "solmate/tokens/ERC721.sol";

contract CounterScript is Script {
  uint256 cantoNormalAmount = 45_000;

  function setUp() public {}

  function run() public {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerPrivateKey);

    PonzuPalace palace = new PonzuPalace();

    PonzuRewardsManager rewardsManager = new PonzuRewardsManager(
      address(palace),
      palace.turnstileId(),
      bytes32(
        0xcd88fd86a2a81828d829ead5f0b0201e27ca41216de6592e81342feca71f8610
      )
    );
    Owned(rewardsManager).transferOwnership(address(palace));
    palace.registerRewardsManager(address(rewardsManager));
    ERC721(address(palace.turnstile())).transferFrom(
      0xb8155b0adf0408bBe433580dF1c216105587Ee60,
      address(rewardsManager),
      palace.turnstileId()
    );

    palace.pourPonzu();

    uint256 cantoBaseLiquidity = cantoNormalAmount * 1e18;

    palace.pourPonzuPool{value: cantoBaseLiquidity}(cantoBaseLiquidity);
    // palace.markItReady();

    vm.stopBroadcast();
  }
}
