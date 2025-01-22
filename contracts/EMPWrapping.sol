// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title EMP Wrapping Contract
/// @author YourName
/// @notice Allows wrapping and unwrapping of EMP tokens into WEMP tokens
contract EMPWrapping is ERC20 {
    using SafeERC20 for IERC20;
    address public Owner;

    IERC20 public immutable EMP;

    // Event to track wrapping actions
    event Wrapped(address indexed user, uint256 amount);
    // Event to track unwrapping actions
    event Unwrapped(address indexed user, uint256 amount);

    /// @notice Constructor to initialize the EMP token and WEMP details
    /// @param _empAddress The address of the EMP token contract
    constructor(address _empAddress) ERC20("Wrapped EMP", "WEMP") {
        require(_empAddress != address(0), "Invalid EMP token address");
        Owner = msg.sender;
        EMP = IERC20(_empAddress);
    }

    /// @notice Wrap EMP tokens into WEMP tokens
    /// @param amount The amount of EMP tokens to wrap
    function wrap(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        // Ensure the user has approved the contract to transfer EMP tokens
        uint256 allowance = EMP.allowance(msg.sender, address(this));
        require(allowance >= amount, "Allowance too low for transfer");

        // Transfer EMP tokens from the user to this contract using SafeERC20
        EMP.safeTransferFrom(msg.sender, address(this), amount);

        // Mint equivalent WEMP tokens to the user
        _mint(msg.sender, amount);

        // Emit the Wrapped event
        emit Wrapped(msg.sender, amount);
    }

    /// @notice Unwrap WEMP tokens back into EMP tokens
    /// @param amount The amount of WEMP tokens to unwrap
    function unwrap(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        // Ensure the contract has enough EMP tokens to perform the unwrap
        uint256 contractBalance = EMP.balanceOf(address(this));
        require(
            contractBalance >= amount,
            "Not enough EMP tokens in the contract"
        );

        // Burn the WEMP tokens from the user
        _burn(msg.sender, amount);

        // Transfer equivalent EMP tokens back to the user using SafeERC20
        EMP.safeTransfer(msg.sender, amount);

        // Emit the Unwrapped event
        emit Unwrapped(msg.sender, amount);
    }

    /// @notice Owner can withdraw any EMP tokens from the contract (e.g. in emergency)
    /// @param amount The amount of EMP tokens to withdraw
    function withdrawEMP(uint256 amount) external {
        uint256 contractBalance = EMP.balanceOf(address(this));
        require(
            contractBalance >= amount,
            "Not enough EMP tokens in the contract"
        );

        EMP.safeTransfer(Owner, amount);
    }
}
