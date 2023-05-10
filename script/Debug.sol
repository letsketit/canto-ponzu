// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/PonzuPalace.sol";
import {PonzuRewardsManager} from "../src/PonzuRewardsManager.sol";
import "solmate/tokens/ERC721.sol";

contract CounterScript is Script {
  function setUp() public {}

  function run() public {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerPrivateKey);

    PonzuPalace palace = PonzuPalace(
      payable(0x4f1be0c227346e4FD6337c202C80901A06338a42)
    );

    palace.markItReady();
    vm.stopBroadcast();
  }
}
