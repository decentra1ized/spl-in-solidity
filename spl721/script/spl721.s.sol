// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Spl721} from "../src/spl721.sol";

contract Spl721Script is Script {
    Spl721 public spl721;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        spl721 = new Spl721();

        vm.stopBroadcast();
    }
}