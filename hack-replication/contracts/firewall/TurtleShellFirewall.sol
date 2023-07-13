// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ITurtleShellFirewall.sol";

/**
 * @title TurtleShellFirewall
 * @notice This contract is the TurtleShell Firewall implementation, which can be used by any contract to implement an
 *  on-chain firewall. The firewall can be configured by the contract owner to set a threshold percentage, block
 * interval and start parameter. The firewall works by checking if the parameter for a given user has changed by more
 * than the threshold, when updating it. If the parameter has changed by more than the threshold, the firewall will be
 * activated for the given user. In a sophistaced implementation, the parameter could possible be the result of a
 * mathematical formula, which takes into account vital parameters of a user (protocol) that should not change by more
 * than a certain threshold. The firewall can be manually deactivated and actived by the user (protocol) at any time.
 */
contract TurtleShellFirewall is ITurtleShellFirewall {
    /// @notice This error is thrown if the threshold value is greater than 100 (100%)
    error TurtleShellFirewall__InvalidThresholdValue();
    /// @notice This error is thrown if the block interval is greater than the total number of blocks
    error TurtleShellFirewall__InvalidBlockInterval();
    /// @notice This error is thrown if the cooldown period is greater than the total number of blocks
    error TurtleShellFirewall__InvalidCooldownPeriod();
    /// @notice This error is thrown if the startParameter is too big to be multiplied by the threshold percentage
    error TurtleShellFirewall__InvalidConfigValues();
    /// @notice This error is thrown if the parameter is decreased bellow zero
    error TurtleShellFirewall__CannotHaveNegativeParameter();

    /// @dev Firewall configuration values for a given user
    struct FirewallConfig {
        /// @dev threshold for changes as a percentage (represented as an integer)
        uint8 thresholdPercentage;
        /// @dev the number of blocks to "go-back" to find reference paramter for Firewall check
        uint256 blockInterval;
        /// @dev the number of blocks to wait before switch off the firewall after it has been triggered
        uint256 cooldownPeriod;
    }

    struct ParameterData {
        uint256 parameter;
        uint256 blockNumber;
    }

    /// @dev Dynamic firewall state data for a given user
    struct FirewallData {
        mapping(uint32 nonce => ParameterData) parameters;
        // TODO: remove this and use the block number as indicator for the firewall status (0 for false)
        bool firewallActive;
        uint32 nonce;
        uint256 lastActivatedBlock;
    }

    mapping(address => FirewallData) private s_firewallData;
    mapping(address => FirewallConfig) private s_firewallConfig;

    /**
     * @notice Function for setting the parameter for a given user
     * @param newParamter The new parameter to set
     * @dev This function is internal and should only be called by the contract itself
     * This function emits the {ParameterChanged} event
     */
    function _setParameter(uint256 newParamter) internal {
        uint32 nonce = s_firewallData[msg.sender].nonce;
        s_firewallData[msg.sender].parameters[nonce] = ParameterData(newParamter, block.number);
        s_firewallData[msg.sender].nonce++;
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

        // Finding the ParameterData with a block number closest to 'block.number - m_firewallConfig.blockInterval'
        uint256 targetBlockNumber = block.number - m_firewallConfig.blockInterval;
        uint256 referenceParameter;
        uint32 nonce = s_firewallData[msg.sender].nonce;
        for (uint32 i = nonce; i > 0; i--) {
            if (s_firewallData[msg.sender].parameters[i - 1].blockNumber <= targetBlockNumber) {
                // TODO: find a solution to avoid accessing storage at every iteration (possibly store the value as an array in memory)
                referenceParameter = s_firewallData[msg.sender].parameters[i - 1].parameter;
                break;
            }
        }

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
    function setParameter(uint256 newParameter) public returns (bool) {
        FirewallConfig memory m_firewallConfig = s_firewallConfig[msg.sender];

        /// @dev gas savings by skipping threshold check in case of active firewall
        if (s_firewallData[msg.sender].firewallActive) {
            /// @dev check if the cooldown period has passed
            if (block.number - s_firewallData[msg.sender].lastActivatedBlock > m_firewallConfig.cooldownPeriod) {
                _setFirewallStatus(false);
            }

            _setParameter(newParameter);
            return true;
        }

        bool triggerFirewall = _checkIfParameterUpdateExceedsThreshold(newParameter);
        if (triggerFirewall) _setFirewallStatus(true);

        _setParameter(newParameter);
        return triggerFirewall;
    }

    /**
     * @notice Function for increasing the security parameter
     * @dev This function can be called by any user to increase their security parameter.
     *
     * @param increaseAmount is the amount by which to increase the parameter
     * @return Returns true if the firewall was activated, or had already been active
     */
    function increaseParameter(uint256 increaseAmount) external returns (bool) {
        uint256 newParameter = getParameterOf(msg.sender) + increaseAmount;
        return setParameter(newParameter);
    }

    /**
     * @notice Function for decreasing the security parameter
     * @dev This function can be called by any user to decrease their security parameter.
     *
     * Emits the {ParameterChanged} event
     * Emits the {FirewallStatusUpdate} event
     * @param decreaseAmount is the amount by which to decrease the parameter
     * @return Returns true if the firewall was activated, or had already been active
     */
    function decreaseParameter(uint256 decreaseAmount) external returns (bool) {
        uint256 currentParameter = getParameterOf(msg.sender);
        if (currentParameter < decreaseAmount) revert TurtleShellFirewall__CannotHaveNegativeParameter();
        uint256 newParameter = currentParameter - decreaseAmount;
        return setParameter(newParameter);
    }

    /**
     * @notice Function for setting the configuration values for a firewall user
     * @param thresholdPercentage The threshold percentage to set for the firewall
     * @param blockInterval The block interval to set for the firewall
     * @param startParameter The start parameter to set for the firewall
     * @param cooldownPeriod The cooldown period to set for the firewall
     * @dev The function emits the {ParameterChanged} event
     */
    function setUserConfig(
        uint8 thresholdPercentage,
        uint256 blockInterval,
        uint256 startParameter,
        uint256 cooldownPeriod
    )
        external
    {
        if (thresholdPercentage > 100 || thresholdPercentage == 0) revert TurtleShellFirewall__InvalidThresholdValue();
        if (blockInterval > block.number) revert TurtleShellFirewall__InvalidBlockInterval();
        if (cooldownPeriod > block.number) revert TurtleShellFirewall__InvalidCooldownPeriod();
        if (startParameter > type(uint256).max / thresholdPercentage) revert TurtleShellFirewall__InvalidConfigValues();

        s_firewallConfig[msg.sender] = FirewallConfig(thresholdPercentage, blockInterval, cooldownPeriod);
        _setParameter(startParameter);
    }

    /// @inheritdoc ITurtleShellFirewall
    function setFirewallStatus(bool newStatus) external {
        _setFirewallStatus(newStatus);
    }

    /// @inheritdoc ITurtleShellFirewall
    function getFirewallStatusOf(address user) external view returns (bool) {
        return s_firewallData[user].firewallActive;
    }

    /// @inheritdoc ITurtleShellFirewall
    function getParameterOf(address user) public view returns (uint256) {
        return s_firewallData[user].parameters[s_firewallData[user].nonce - 1].parameter;
    }

    /// @inheritdoc ITurtleShellFirewall
    function getSecurityParameterConfigOf(address user) external view returns (uint8, uint256) {
        FirewallConfig memory m_firewallConfig = s_firewallConfig[user];
        return (m_firewallConfig.thresholdPercentage, m_firewallConfig.blockInterval);
    }
}
