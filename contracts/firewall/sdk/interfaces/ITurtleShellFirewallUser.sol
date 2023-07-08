// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ITurtleShellFirewallUser - Interface for the TurtleShell contract
 * @notice This interface includes methods for checking if the firewall is triggered, for tracking any parameter,
 * setting security
 * parameters in a protocol
 */
interface ITurtleShellFirewallUser {
    /// @notice Set security parameters for the calling protocol
    /// @param treshold The threshold as a percentage (represented as an integer)
    /// @param numberOfBlocks The number of blocks to use for checking the threshold
    function setSecurityParameter(uint256 treshold, uint8 numberOfBlocks) external;

    /// @notice Decrease the parameter for the calling protocol by a given amount
    /// @param amount The amount to decrease the parameter by
    function decreaseParameter(uint256 amount) external;

    /// @notice Increase the parameter for the calling protocol by a given amount
    /// @param amount The amount to increase the parameter by
    function increaseParameter(uint256 amount) external;

    /// @notice Check if the parameter has decreased more than the set threshold since a set number of blocks ago
    /// @return Returns true if the parameter has decreased more than the threshold, false otherwise
    function getFirewallStatus() external returns (bool);
}
