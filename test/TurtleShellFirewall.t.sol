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

    function testFuzz_setUserConfig_revertsIfThresholdExceeding(uint8 thresholdPercentage) public {
        vm.assume(thresholdPercentage > 100);

        vm.expectRevert(abi.encodeWithSelector(TurtleShellFirewall.TurtleShellFirewall__InvalidThresholdValue.selector));
        turtleShellFirewall.setUserConfig(thresholdPercentage, 1, 1, 1);
    }

    function testFuzz_setUserConfig_revertsIfInvalidBlockInterval(uint256 blockInterval, uint256 blockNumber) public {
        vm.assume(blockInterval > blockNumber);
        vm.roll(blockNumber);

        vm.expectRevert(abi.encodeWithSelector(TurtleShellFirewall.TurtleShellFirewall__InvalidBlockInterval.selector));
        turtleShellFirewall.setUserConfig(5, blockInterval, blockNumber, 1);
    }

    function testFuzz_setUserConfig_revertsIfInvalidConfigValues(
        uint256 startParameter,
        uint8 thresholdPercentage
    )
        public
    {
        vm.roll(1);
        vm.assume(thresholdPercentage <= 100 && thresholdPercentage != 0);
        vm.assume(startParameter > type(uint256).max / thresholdPercentage);

        vm.expectRevert(abi.encodeWithSelector(TurtleShellFirewall.TurtleShellFirewall__InvalidConfigValues.selector));
        turtleShellFirewall.setUserConfig(thresholdPercentage, 1, startParameter, 1);
    }

    function testFuzz_setUserConfig_setsConfig(
        uint256 blockInterval,
        uint8 thresholdPercentage,
        uint256 startParameter
    )
        public
    {
        vm.assume(thresholdPercentage <= 100 && thresholdPercentage != 0);
        vm.assume(startParameter < type(uint256).max / thresholdPercentage);
        vm.roll(blockInterval);

        turtleShellFirewall.setUserConfig(thresholdPercentage, blockInterval, startParameter, 1);

        (uint8 retrievedThreshold, uint256 retrievedInterval) =
            turtleShellFirewall.getSecurityParameterConfigOf(address(this));
        uint256 retrievedStartParameter = turtleShellFirewall.getParameterOf(address(this));

        assertEq(retrievedThreshold, thresholdPercentage);
        assertEq(retrievedInterval, blockInterval);
        assertEq(retrievedStartParameter, startParameter);

        // TODO: test if emits event
    }

    function testSetFirewallStatus() public {
        assertEq(turtleShellFirewall.getFirewallStatusOf(address(this)), false);

        turtleShellFirewall.setFirewallStatus(true);

        assertEq(turtleShellFirewall.getFirewallStatusOf(address(this)), true);

        // TODO: test if emits event
    }

    function testFuzz_setParameter_setsNewParameter(
        uint256 blockInterval,
        uint8 thresholdPercentage,
        uint256 startParameter,
        uint256 newParameter
    )
        public
    {
        vm.assume(thresholdPercentage <= 100 && thresholdPercentage != 0);
        vm.assume(startParameter < type(uint256).max / thresholdPercentage);
        vm.roll(blockInterval);

        turtleShellFirewall.setUserConfig(thresholdPercentage, blockInterval, startParameter, 1);

        turtleShellFirewall.setParameter(newParameter);
        assertEq(turtleShellFirewall.getParameterOf(address(this)), newParameter);

        // TODO: check event being emitted
    }

    function testFuzz_updateParamter_returnsTrueIfFirewallAlreadyActive(
        uint256 blockInterval,
        uint8 thresholdPercentage,
        uint256 startParameter,
        uint256 newParameter
    )
        public
    {
        vm.assume(thresholdPercentage <= 100 && thresholdPercentage != 0);
        vm.assume(startParameter < type(uint256).max / thresholdPercentage);
        vm.roll(blockInterval);

        turtleShellFirewall.setUserConfig(thresholdPercentage, blockInterval, startParameter, 1);
        turtleShellFirewall.setFirewallStatus(true);

        assertEq(turtleShellFirewall.setParameter(newParameter), true);
        assertEq(turtleShellFirewall.getParameterOf(address(this)), newParameter);
    }

    function testFuzz_setParameter_triggersFirewallIfNewParamterExceedsThreshold(
        uint256 blockInterval,
        uint8 thresholdPercentage,
        uint256 startParameter,
        uint256 newParameter
    )
        public
    {
        vm.assume(thresholdPercentage <= 100 && thresholdPercentage != 0);
        vm.assume(startParameter < type(uint256).max / thresholdPercentage);

        vm.assume(startParameter != 0);
        vm.assume(blockInterval < 20 && blockInterval > 0);

        if (newParameter > startParameter) {
            vm.assume(newParameter - startParameter > (startParameter * thresholdPercentage / 100));
        } else {
            vm.assume(startParameter - newParameter > (startParameter * thresholdPercentage / 100));
        }

        vm.roll(blockInterval);
        turtleShellFirewall.setUserConfig(thresholdPercentage, blockInterval, startParameter, 1);

        for (uint256 i = 1; i <= blockInterval; i++) {
            turtleShellFirewall.setParameter(startParameter);
            vm.roll(blockInterval + i);
        }

        assertEq(turtleShellFirewall.setParameter(newParameter), true);
        assertEq(turtleShellFirewall.getFirewallStatusOf(address(this)), true);
        assertEq(turtleShellFirewall.getParameterOf(address(this)), newParameter);
    }
}
