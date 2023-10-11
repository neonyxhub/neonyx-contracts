// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {strings} from "stringutils/strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IdentityChecker} from "contracts/did/IdentityChecker.sol";

import {IIdentityManager} from "interfaces/did/IIdentityManager.sol";
import {INeonyxNameServicePayments} from "interfaces/name_service/INeonyxNameServicePayments.sol";
import {INeonyxNameServiceReserve} from "interfaces/name_service/INeonyxNameServiceReserve.sol";
import {INeonyxNameServiceStorage, Name} from "interfaces/name_service/INeonyxNameServiceStorage.sol";

contract NeonyxNameServicePayments is INeonyxNameServicePayments, IdentityChecker, Ownable {
    uint32 public constant gracePeriod = 90 days;
    uint32 public constant timeframeSize = 365 days;
    uint256 public pricePerTimeframe; // name price

    INeonyxNameServiceStorage public immutable nameService;
    INeonyxNameServiceReserve public immutable reservations;

    constructor(
        uint256 _namePrice,
        INeonyxNameServiceStorage _nameService,
        INeonyxNameServiceReserve _reservations,
        IIdentityManager _identityManger
    ) IdentityChecker(_identityManger) Ownable() {
        pricePerTimeframe = _namePrice;
        nameService = _nameService;
        reservations = _reservations;
    }

    /**
     * @dev internal function to get owner of name taking into account grace period.
     * @param _name Name to find owner.
     * @return owner nxid
     */
    function _getNameHolder(string memory _name) internal view returns (address) {
        Name memory name = nameService.getName(_name);

        if (name.ttl + gracePeriod < block.timestamp) {
            return address(0);
        }
        return name.owner;
    }

    /// @inheritdoc INeonyxNameServicePayments
    function renewName(address _minterNxid, string memory _name, uint256 _timeframeAmount)
        external
        payable
        onlyAdmin(_minterNxid)
    {
        Name memory name = nameService.getName(_name);
        require(name.owner == _minterNxid, "You are not an owner.");
        require(msg.value >= pricePerTimeframe * _timeframeAmount, "Value below price.");

        nameService.increaseTtl(_name, timeframeSize * _timeframeAmount);
        emit NameRenewed(_name);
    }

    /// @inheritdoc INeonyxNameServicePayments
    function mint(address _minterNxid, string memory _name, uint256 _timeframeAmount)
        external
        payable
        onlyAdmin(_minterNxid)
        returns (uint256)
    {
        require(_timeframeAmount > 0, "Timeframes amount must be grater than zero.");
        require(msg.value >= pricePerTimeframe * _timeframeAmount, "Value below price.");

        require(reservations.isOwner(_name, _minterNxid), "This name is reserved.");
        require(_getNameHolder(_name) == address(0), "This name already exists.");

        (bool sent,) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether.");

        return nameService.mintName(_name, _minterNxid, timeframeSize * _timeframeAmount);
    }

    /// @inheritdoc INeonyxNameServicePayments
    function changePrice(uint256 _price) external onlyOwner {
        pricePerTimeframe = _price;
        emit PriceChanged(_price);
    }
}
