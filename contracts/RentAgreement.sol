// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RentAgreement {
    address payable public immutable landlord;
    address payable public immutable tenant;
    IERC20 public immutable rentToken;

    bool public immutable isNative;

    uint256 public rentAmount;
    uint256 public nextDueDate;
    uint256 public lateFee;

    using SafeERC20 for IERC20;

    event RentPaid(address indexed tenant, uint256 amount, uint256 timestamp);
    event PaymentMissed(address indexed tenant, uint256 timestamp);

    constructor(
        address payable _landlord,
        address payable _tenant,
        uint256 _rentAmount,
        uint256 _startDueDate,
        uint256 _lateFee,
        address _tokenAddress,
        bool _isNative
    ) {
        landlord = _landlord;
        tenant = _tenant;
        rentAmount = _rentAmount;
        nextDueDate = _startDueDate;
        lateFee = _lateFee;
        isNative = _isNative;
        if (!isNative) {
            rentToken = IERC20(_tokenAddress);
        }
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only tenant can pay rent");
        _;
    }

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only landlord have access to this");
        _;
    }

    function payRent() external payable onlyTenant {
        uint256 totalDue = rentAmount;

        if (block.timestamp > nextDueDate) {
            totalDue += lateFee;
            emit PaymentMissed(tenant, block.timestamp);
        }

        if (isNative) {
            require(msg.value >= totalDue, "Insufficient rent payment");

            if (msg.value > totalDue) {
                payable(msg.sender).transfer(msg.value - totalDue);
            }
        } else {
            require(
                rentToken.transferFrom(msg.sender, address(this), totalDue),
                "Token transfer failed"
            );
        }

        nextDueDate += 30 days;

        emit RentPaid(tenant, msg.value, block.timestamp);
    }

    function withdraw() external onlyLandlord {
        if (isNative) {
            uint256 amount = address(this).balance;
            require(amount > 0, "No funds to withdraw");
            (bool success, ) = landlord.call{value: amount}("");
            require(success, "Withdrawal failed");
        } else {
            uint256 amount = rentToken.balanceOf(address(this));
            require(amount > 0, "No funds to withdraw");
            rentToken.safeTransfer(landlord, amount);
        }
    }

    // function depositToAave() {
        
    // }

    function getNextDueDate() external view returns (uint256) {
        return nextDueDate;
    }
}
