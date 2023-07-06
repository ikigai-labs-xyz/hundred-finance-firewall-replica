// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title TurtleShellFirewall - Firewall implementation, tracks Total Value Locked (TVL) for protocols
/// @notice This contract allows protocols to track their TVL and set security parameters.
/// Protocol can increase or decrease their TVL and set a threshold and a number of blocks as security parameters.
/// Protocol can then check the firewall status to check if its TVL has decreased more than its set threshold since a
/// set number of blocks ago.
contract TurtleShellFirewall {
    struct FirewallConfig {
        /// @dev threshold for changes as a percentage (represented as an integer)
        uint256 thresholdPercentage;
        /// @dev the number of blocks to "go-back" to find reference paramter for Firewall check
        uint256 blockInterval;
    }

    struct FirewallData {
        mapping(uint256 => uint256) parameters;
        bool firewallActive;
    }

    mapping(address => FirewallData) private s_firewallData;
    mapping(address => FirewallConfig) private s_firewallConfig;

    event ParamterChanged(address indexed user, uint256 newParameter);
    event FirewallStatusUpdate(address indexed user, bool indexed newStatus);

    /**
     * @notice Function for setting the parameter for a given user
     * @param newParamter The new parameter to set
     * @dev This function is internal and should only be called by the contract itself
     * This function emits the {ParamterChanged} event
     */
    function _setParameter(uint256 newParamter) internal {
        s_firewallData[msg.sender].parameters[block.number] = newParamter;
        emit ParamterChanged(msg.sender, newParamter);
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
     * @return Returns true if the parameter update exceeds the threshold, false otherwise
     */
    function _checkIfParameterUpdateExceedsThreshold(uint256 newParameter) internal view returns (bool) {
        FirewallConfig memory m_firewallConfig = s_firewallConfig[msg.sender];
        uint256 referenceParameter =
            s_firewallData[msg.sender].parameters[block.number - m_firewallConfig.blockInterval];
        uint256 thresholdAmount = (referenceParameter * m_firewallConfig.thresholdPercentage) / 100;

        // console.log("Blocks to reference: %s", m_firewallConfig.blockInterval);
        // console.log("Threshold percentage: %s", m_firewallConfig.thresholdPercentage);
        // console.log("Threshold amount: %s", thresholdAmount);
        // console.log("Reference parameter: %s", referenceParameter);
        // console.log("New parameter: %s", newParameter);

        if (newParameter > referenceParameter) {
            return newParameter - referenceParameter >= thresholdAmount;
        } else {
            return referenceParameter - newParameter >= thresholdAmount;
        }
    }

    /**
     * @notice Function for updating the parameter
     * @param newParameter is the new parameter
     * @return Returns true if the parameter update exceeds the threshold (triggers firewall), false otherwise
     */
    function updateParameter(uint256 newParameter) external returns (bool) {
        /// @dev gas savings by skipping threshold check in case of active firewall
        if (s_firewallData[msg.sender].firewallActive) {
            _setParameter(newParameter);
            return false;
        }

        bool triggerFirewall = _checkIfParameterUpdateExceedsThreshold(newParameter);
        if (triggerFirewall) _setFirewallStatus(true);

        // console.log("Firewall triggered: %s", triggerFirewall);

        _setParameter(newParameter);
        return triggerFirewall;
    }

    /// @notice Function for setting security configuration for the user (protocol)
    /// @param tresholdPercentage The threshold as a percentage (represented as an integer)
    function setUserConfig(uint256 tresholdPercentage, uint256 blockInterval, uint256 startParameter) external {
        s_firewallConfig[msg.sender] = FirewallConfig(tresholdPercentage, blockInterval);
        _setParameter(startParameter);
    }

    function setFirewallStatus(bool newStatus) external {
        _setFirewallStatus(newStatus);
    }

    /// @notice Check if the firewall is active: the firewall is trigerred when the TVL has decreased more than the set
    /// threshold since a set number of blocks ago
    /// @return Returns true if the TVL has decreased more than the threshold, false otherwise
    function getFirewallStatus() external view returns (bool) {
        return s_firewallData[msg.sender].firewallActive;
    }

    /// @notice Get the current paramter for a given user
    /// @param user The address of the user to get the paramter for
    /// @return Returns the current paramter of the user
    function getParameterOf(address user) external view returns (uint256) {
        return s_firewallData[user].parameters[block.number];
    }

    /// @notice Get the security parameters for a given protocol
    /// @param user The address of the protocol to get the security parameters for
    /// @return Returns the threshold and number of blocks set as security parameters for the protocol
    function getSecurityParameterConfigOf(address user) external view returns (uint256, uint256) {
        FirewallConfig memory m_firewallConfig = s_firewallConfig[user];
        return (m_firewallConfig.thresholdPercentage, m_firewallConfig.blockInterval);
    }
}
