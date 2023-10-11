// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./INeonyxNameServiceReserve.sol";
import "./INeonyxNameServiceStorage.sol";

interface INeonyxNameServicePayments {
    event NameRenewed(string fullNameName);
    event PriceChanged(uint256 newPrice);

    function gracePeriod() external view returns (uint32);

    function timeframeSize() external view returns (uint32);

    function pricePerTimeframe() external view returns (uint256);

    function nameService() external view returns (INeonyxNameServiceStorage);

    function reservations() external view returns (INeonyxNameServiceReserve);

    /**
     * @notice Renew a name.
     * @param _minterNxid nxid of minter.
     * @param _name Name to renew.
     * @param _timeframeAmount Amount of timeframes to renew.
     */
    function renewName(address _minterNxid, string memory _name, uint256 _timeframeAmount) external payable;

    /**
     * @notice Mint a new name as NFT (no dots and spaces allowed).
     * @param _minterNxid nxid of minter.
     * @param _name Name to mint.
     * @param _timeframeAmount Amount of timeframes.
     * @return token ID
     */
    function mint(address _minterNxid, string memory _name, uint256 _timeframeAmount)
        external
        payable
        returns (uint256);

    /**
     * @notice Changes price per timeframe.
     * @param _price new price.
     */
    function changePrice(uint256 _price) external;
}
