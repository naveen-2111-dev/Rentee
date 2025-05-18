// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./RentAgreement.sol";

contract RentFactory {
    mapping(address => bool) public landlords;

    function registerAsLandlord() external {
        landlords[msg.sender] = true;
    }

    struct House {
        uint256 id;
        string description;
    }

    mapping(address => House[]) public landlordHouses;
    mapping(address => address[]) public tenantContracts;

    mapping(address => mapping(uint256 => mapping(address => address)))
        public rentAgreements;

    uint256 public houseCount;

    event HouseAdded(address landlord, uint256 houseId, string description);
    event TenantAdded(
        address landlord,
        uint256 houseId,
        address tenant,
        address rentContract
    );

    modifier onlyLandlord() {
        require(landlords[msg.sender], "Only landlords allowed");
        _;
    }

    function addHouse(string calldata description)
        external
        onlyLandlord
        returns (uint256)
    {
        houseCount++;
        House memory newHouse = House(houseCount, description);
        landlordHouses[msg.sender].push(newHouse);
        emit HouseAdded(msg.sender, houseCount, description);
        return houseCount;
    }

    function addTenant(
        uint256 houseId,
        address payable tenant,
        uint256 rentAmount,
        uint256 startDueDate,
        uint256 lateFee,
        address _tokenAddress,
        bool _isNative
    ) external onlyLandlord returns (address) {
        require(houseExists(msg.sender, houseId), "House does not exist");

        require(
            rentAgreements[msg.sender][houseId][tenant] == address(0),
            "Tenant already exists"
        );

        RentAgreement newRent = new RentAgreement(
            payable(msg.sender),
            tenant,
            rentAmount,
            startDueDate,
            lateFee,
            _tokenAddress,
            _isNative
        );

        rentAgreements[msg.sender][houseId][tenant] = address(newRent);
        tenantContracts[tenant].push(address(newRent));

        emit TenantAdded(msg.sender, houseId, tenant, address(newRent));

        return address(newRent);
    }

    function houseExists(address landlord, uint256 houseId)
        public
        view
        returns (bool)
    {
        House[] memory houses = landlordHouses[landlord];
        for (uint256 i = 0; i < houses.length; i++) {
            if (houses[i].id == houseId) {
                return true;
            }
        }
        return false;
    }

    function getHouses(address landlord)
        external
        view
        returns (House[] memory)
    {
        return landlordHouses[landlord];
    }

    function getTenantContracts(address tenant)
        external
        view
        returns (address[] memory)
    {
        return tenantContracts[tenant];
    }

    function getRentAgreement(
        address landlord,
        uint256 houseId,
        address tenant
    ) external view returns (address) {
        return rentAgreements[landlord][houseId][tenant];
    }
}
