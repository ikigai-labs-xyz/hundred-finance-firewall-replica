// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ITurtleShellFirewallUser } from "./ITurtleShellFirewallUser.sol";

/**
 * @title ITurtleShellTvlTracker - Interface for the TurtleShell contract
 * @notice This interface includes methods for checking if the firewall is triggered, for tracking TVL, setting security
 * parameters in a protocol
 */
interface ITurtleShellTvlTracker is ITurtleShellFirewallUser {
    /// @notice Decrease the TVL for the calling protocol by a given amount
    /// @param amount The amount to decrease the TVL by
    function decreaseTVL(uint256 amount) external;

    /// @notice Increase the TVL for the calling protocol by a given amount
    /// @param amount The amount to increase the TVL by
    function increaseTVL(uint256 amount) external;
}
