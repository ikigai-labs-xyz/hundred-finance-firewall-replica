// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ITurtleShellTvlTracker - Interface for the TurtleShell contract
 * @notice This interface includes methods for checking if the firewall is triggered, for tracking TVL, setting security
 * parameters in a protocol
 */
interface ITurtleShellFirewallUser {
    /// @notice Set security parameters for the calling protocol
    /// @param treshold The threshold as a percentage (represented as an integer)
    /// @param numberOfBlocks The number of blocks to use for checking the threshold
    function setSecurityParameter(uint256 treshold, uint8 numberOfBlocks) external;

    /// @notice Check if the TVL has decreased more than the set threshold since a set number of blocks ago
    /// @return Returns true if the TVL has decreased more than the threshold, false otherwise
    function getFirewallStatus() external returns (bool);
}
