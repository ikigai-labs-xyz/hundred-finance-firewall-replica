// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title TurtleShellFirewall
 * @notice This contract is the TurtleShell Firewall implementation, which can be used by any contract to implement an
 on-chain firewall. The firewall can be configured by the contract owner to set a threshold percentage, block interval and
 start parameter. The firewall works by checking if the parameter for a given user has changed by more than the threshold, when
 updating it. If the parameter has changed by more than the threshold, the firewall will be activated for the given user. In a
 sophistaced implementation, the parameter could possible be the result of a mathematical formula, which takes into account vital
 parameters of a user (protocol) that should not change by more than a certain threshold. The firewall can be manually deactivated
 and actived by the user (protocol) at any time.
 */
contract TurtleShellFirewall {
    /// @notice This error is thrown if the threshold value is greater than 100 (100%)
    error TurtleShellFirewall__InvalidThresholdValue();
    /// @notice This error is thrown if the block interval is greater than the total number of blocks
    error TurtleShellFirewall__InvalidBlockInterval();
    /// @notice This error is thrown if the startParameter is too big to be multiplied by the threshold percentage
    error TurtleShellFirewall__InvalidConfigValues();

    /// @dev Firewall configuration values for a given user 
    struct FirewallConfig {
        /// @dev threshold for changes as a percentage (represented as an integer)
        uint8 thresholdPercentage;
        /// @dev the number of blocks to "go-back" to find reference paramter for Firewall check
        uint256 blockInterval;
    }

    /// @dev Dynamic firewall state data for a given user
    struct FirewallData {
        mapping(uint256 => uint256) parameters;
        bool firewallActive;
    }

    mapping(address => FirewallData) private s_firewallData;
    mapping(address => FirewallConfig) private s_firewallConfig;

    /// @notice Event emitted whenever the parameter for a given user gets changed
    event ParameterChanged(address indexed user, uint256 indexed newParameter);
    /// @notice Event emitted whenever the firewall status for a given user gets changed
    event FirewallStatusUpdate(address indexed user, bool indexed newStatus);

    /**
     * @notice Function for setting the parameter for a given user
     * @param newParamter The new parameter to set
     * @dev This function is internal and should only be called by the contract itself
     * This function emits the {ParameterChanged} event
     */
    function _setParameter(uint256 newParamter) internal {
        s_firewallData[msg.sender].parameters[block.number] = newParamter;
        emit ParameterChanged(msg.sender, newParamter);
    }

    /**
     * @notice Function for setting the firewall status for a given user
     * @param newStatus The new status to set
     * @dev This function is internal and should only be called by the contract itself
     * This function emits the {FirewallStatusUpdate} event
     */
    function _setFirewallStatus(bool newStatus) internal {
        s_firewallData[msg.sender].firewallActive = newStatus;
        emit FirewallStatusUpdate(msg.sender, newStatus);
    }

    /**
     * @notice Function for checking if the parameter update is below the threshold
     * @param newParameter The new parameter to check
     * @return bool true if the parameter update exceeds the threshold, false otherwise
     */
    function _checkIfParameterUpdateExceedsThreshold(uint256 newParameter) internal view returns (bool) {
        FirewallConfig memory m_firewallConfig = s_firewallConfig[msg.sender];
        uint256 referenceParameter =
            s_firewallData[msg.sender].parameters[block.number - m_firewallConfig.blockInterval];

        // insufficient data
        if (referenceParameter == 0) return false;

        uint256 thresholdAmount = (referenceParameter * m_firewallConfig.thresholdPercentage) / 100;
        if (newParameter > referenceParameter) {
            return newParameter - referenceParameter >= thresholdAmount;
        } else {
            return referenceParameter - newParameter >= thresholdAmount;
        }
    }

    /**
     * @notice Function for updating the security parameter
     * @dev This function can be called by any user to update their security parameter. If the parameter exceeds the threshold,
     * the firewall will be automatically activated. If the firewall is already active, the parameter will be updated anyways.
     * 
     * Emits the {ParameterChanged} event
     * Emits the {FirewallStatusUpdate} event
     * @param newParameter is the new parameter
     * @return Returns true if the firewall was activated, or had alrady been active
     */
    function updateParameter(uint256 newParameter) external returns (bool) {
        /// @dev gas savings by skipping threshold check in case of active firewall
        if (s_firewallData[msg.sender].firewallActive) {
            _setParameter(newParameter);
            return true;
        }

        bool triggerFirewall = _checkIfParameterUpdateExceedsThreshold(newParameter);
        if (triggerFirewall) _setFirewallStatus(true);

        _setParameter(newParameter);
        return triggerFirewall;
    }

    /**
     * @notice Function for setting the configuration values for a firewall user
     * @param thresholdPercentage The threshold percentage to set for the firewall
     * @param blockInterval The block interval to set for the firewall
     * @dev The function emits the {ParameterChanged} event
     */
    function setUserConfig(uint8 thresholdPercentage, uint256 blockInterval, uint256 startParameter) external {
        if (thresholdPercentage > 100 || thresholdPercentage == 0) revert TurtleShellFirewall__InvalidThresholdValue();
        if (blockInterval > block.number) revert TurtleShellFirewall__InvalidBlockInterval();
        if (startParameter > type(uint256).max / thresholdPercentage) revert TurtleShellFirewall__InvalidConfigValues();

        s_firewallConfig[msg.sender] = FirewallConfig(thresholdPercentage, blockInterval);
        _setParameter(startParameter);
    }

    /**
     * @notice Function for manually setting the firewall status for a given user
     * @param newStatus The new status to set for the firewall
     * @dev This function can be used to manually activate or deactivate the firewall for a given user
     * ATTENTION: This function should especially be used to deactivate the firewall, in case it got triggered.
     * This function emits the {FirewallStatusUpdate} event
     */
    function setFirewallStatus(bool newStatus) external {
        _setFirewallStatus(newStatus);
    }

    /**
     * @notice Function for getting the firewall status for a given user
     * @param user The address to get the firewall status for
     * @return bool if the firewall is active for the given user
     */
    function getFirewallStatusOf(address user) external view returns (bool) {
        return s_firewallData[user].firewallActive;
    }

    /**
     * @notice Function for getting the security parameter for a given firewall user
     * @param user The address of the firewall user
     * @return uint256 the security parameter for the given user
     */
    function getParameterOf(address user) external view returns (uint256) {
        return s_firewallData[user].parameters[block.number];
    }

    /**
     * @notice Function for getting the security parameters for a given address
     * @param user The address to get the security parameters for
     * @return Returns The threshold and block interval set as security parameters for the address
     */
    function getSecurityParameterConfigOf(address user) external view returns (uint8, uint256) {
        FirewallConfig memory m_firewallConfig = s_firewallConfig[user];
        return (m_firewallConfig.thresholdPercentage, m_firewallConfig.blockInterval);
    }
}
