// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import { TurtleShellFirewall } from "../contracts/firewall/TurtleShellFirewall.sol";

contract TurtleShellFirewallTest is Test {
    TurtleShellFirewall public turtleShellFirewall;

    function setUp() public {
        turtleShellFirewall = new TurtleShellFirewall();
    }
}
