// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ITurtleShellFirewall {
    /// @notice Event emitted whenever the parameter for a given user gets changed
    event ParameterChanged(address indexed user, uint256 indexed newParameter);
    /// @notice Event emitted whenever the firewall status for a given user gets changed
    event FirewallStatusUpdate(address indexed user, bool indexed newStatus);

    /**
     * @notice Function for updating the security parameter
     * @dev This function can be called by any user to update their security parameter. If the parameter exceeds the
     * threshold,
     * the firewall will be automatically activated. If the firewall is already active, the parameter will be updated
     * anyways.
     *
     * Emits the {ParameterChanged} event
     * Emits the {FirewallStatusUpdate} event
     * @param newParameter is the new parameter
     * @return Returns true if the firewall was activated, or had alrady been active
     */
    function setParameter(uint256 newParameter) external returns (bool);

    /**
     * @notice Function for setting the configuration values for a firewall user
     * @param thresholdPercentage The threshold percentage to set for the firewall
     * @param blockInterval The block interval to set for the firewall
     * @dev The function emits the {ParameterChanged} event
     */
    function setUserConfig(
        uint8 thresholdPercentage,
        uint256 blockInterval,
        uint256 startParameter,
        uint256 cooldownPeriod
    )
        external;

    /**
     * @notice Function for manually setting the firewall status for a given user
     * @param newStatus The new status to set for the firewall
     * @dev This function can be used to manually activate or deactivate the firewall for a given user
     * ATTENTION: This function should especially be used to deactivate the firewall, in case it got triggered.
     * This function emits the {FirewallStatusUpdate} event
     */
    function setFirewallStatus(bool newStatus) external;

    /**
     * @notice Function for getting the firewall status for a given user
     * @param user The address to get the firewall status for
     * @return bool if the firewall is active for the given user
     */
    function getFirewallStatusOf(address user) external view returns (bool);

    /**
     * @notice Function for getting the security parameter for a given firewall user
     * @param user The address of the firewall user
     * @return uint256 the security parameter for the given user
     */
    function getParameterOf(address user) external view returns (uint256);

    /**
     * @notice Function for getting the security parameters for a given address
     * @param user The address to get the security parameters for
     * @return Returns The threshold and block interval set as security parameters for the address
     */
    function getSecurityParameterConfigOf(address user) external view returns (uint8, uint256);
}
