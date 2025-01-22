// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title DOLA Token Contract
/// @notice A stablecoin pegged to 1 USD, backed by BDOLA as collateral.
contract DOLAToken is ERC20 {
    IERC20 public bdolaToken; // BDOLA token used as collateral
    uint256 public collateralizationRatio = 150; // 150% collateralization

    constructor(address _bdolaToken) ERC20("DOLA", "DOLA") {
        bdolaToken = IERC20(_bdolaToken);
    }

    /// @notice Calculates the required BDOLA collateral for a given DOLA amount
    /// @param dolaAmount The amount of DOLA to mint
    /// @return The required collateral in BDOLA (1.5x DOLA amount for 150% collateralization)
    function calculateCollateral(
        uint256 dolaAmount
    ) public view returns (uint256) {
        return (dolaAmount * collateralizationRatio) / 100;
    }

    /// @notice Mints DOLA tokens by locking BDOLA as collateral
    /// @param dolaAmount The amount of DOLA to mint
    function mintDOLA(uint256 dolaAmount) external {
        uint256 requiredCollateral = calculateCollateral(dolaAmount);
        require(
            bdolaToken.balanceOf(msg.sender) >= requiredCollateral,
            "Insufficient BDOLA balance"
        );

        // Transfer BDOLA collateral from the user to the contract
        bdolaToken.transferFrom(msg.sender, address(this), requiredCollateral);

        // Mint DOLA tokens to the user
        _mint(msg.sender, dolaAmount);
    }

    /// @notice Burns DOLA tokens to release collateral
    /// @param dolaAmount The amount of DOLA to burn
    function burnDOLA(uint256 dolaAmount) external {
        require(
            balanceOf(msg.sender) >= dolaAmount,
            "Insufficient DOLA balance"
        );

        uint256 collateralToReturn = calculateCollateral(dolaAmount);

        // Burn the DOLA tokens from the user
        _burn(msg.sender, dolaAmount);

        // Transfer equivalent BDOLA collateral back to the user
        bdolaToken.transfer(msg.sender, collateralToReturn);
    }
}
