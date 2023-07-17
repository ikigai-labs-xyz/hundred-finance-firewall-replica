// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";

import {TurtleShellFirewall} from "../contracts/firewall/TurtleShellFirewall.sol";

contract TurtleShellFirewallScript is Script {
    TurtleShellFirewall public turtleShellFirewall;

    function run() public {
        setUp();
    }

    function setUp() public {
        turtleShellFirewall = new TurtleShellFirewall();
    }

    function setConfig() public {
        turtleShellFirewall.setUserConfig(10, 1, 1, 1);
    }
}
