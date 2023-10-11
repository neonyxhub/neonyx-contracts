// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {NeonyxNameServiceStorage, Name} from "contracts/name_service/NeonyxNameServiceStorage.sol";
import {NeonyxNameServiceReserve} from "contracts/name_service/NeonyxNameServiceReserve.sol";
import {NeonyxNameServicePayments} from "contracts/name_service/NeonyxNameServicePayments.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IdentityManager} from "contracts/did/IdentityManager.sol";
import "forge-std/Test.sol";

contract NeonyxNameServicePaymentsTest is Test {
    event NameRenewed(string fullNameName);
    event PriceChanged(uint256 newPrice);

    NeonyxNameServiceReserve internal nameServiceReserve;
    NeonyxNameServiceStorage internal nameService;
    IdentityManager internal identityManager;
    NeonyxNameServicePayments internal nameServicePayments;
    address internal deployer = address(0x12345);

    string internal name = "name";

    function setUp() external {
        vm.startPrank(deployer);
        nameService = new NeonyxNameServiceStorage();
        nameServiceReserve = new NeonyxNameServiceReserve();
        identityManager = new IdentityManager();
        nameServicePayments = new NeonyxNameServicePayments(0, nameService, nameServiceReserve, identityManager);
        nameService.grantRole(nameService.ADMIN_ROLE(), address(nameServicePayments));
        vm.stopPrank();
    }

    function test_ChangePrice(uint256 newPrice) external {
        assertEq(nameServicePayments.pricePerTimeframe(), 0);
        vm.expectEmit();
        emit PriceChanged(newPrice);
        vm.prank(deployer);
        nameServicePayments.changePrice(newPrice);
        assertEq(nameServicePayments.pricePerTimeframe(), newPrice);
    }

    function test_MintNoPayment(uint256 timeframeAmount) external {
        vm.assume(timeframeAmount > 0);
        vm.assume(type(uint256).max / nameServicePayments.timeframeSize() > timeframeAmount);
        nameServicePayments.mint(address(this), name, timeframeAmount);
        Name memory nameData = nameService.getName(name);
        assertEq(nameData.owner, address(this));
        assertEq(nameData.ttl, block.timestamp + nameServicePayments.timeframeSize() * timeframeAmount);
    }

    function test_MintNameWithPayment(uint256 price) external {
        uint256 timeframeAmount = 1;
        vm.assume(price != 0);
        vm.assume(type(uint256).max / price > timeframeAmount);
        vm.assume(type(uint256).max / nameServicePayments.timeframeSize() > timeframeAmount);

        vm.prank(deployer);
        nameServicePayments.changePrice(price);
        deal(address(this), price * timeframeAmount);

        assertEq(deployer.balance, 0);
        assertEq(address(this).balance, price * timeframeAmount);

        nameServicePayments.mint{value: price * timeframeAmount}(address(this), name, timeframeAmount);

        assertEq(deployer.balance, price * timeframeAmount);
        assertEq(address(this).balance, 0);
    }

    function test_RevertIf_MintIfTimeframeAmountIsZero() external {
        vm.expectRevert("Timeframes amount must be grater than zero.");
        nameServicePayments.mint(address(this), name, 0);
    }

    function test_RevertIf_MintIfPaymentIsNotEnough() external {
        vm.prank(deployer);
        nameServicePayments.changePrice(1);

        vm.expectRevert("Value below price.");
        nameServicePayments.mint{value: 0}(address(this), name, 1);
    }

    function test_RevertIf_MintIfReserved() external {
        vm.prank(deployer);
        nameServiceReserve.reserveName(name, deployer);

        vm.expectRevert("This name is reserved.");
        nameServicePayments.mint{value: 0}(address(this), name, 1);
    }

    function test_RevertIf_MintIfAlreadyExist() external {
        nameServicePayments.mint{value: 0}(address(this), name, 1);
        vm.expectRevert("This name already exists.");
        nameServicePayments.mint{value: 0}(address(this), name, 1);
    }

    function test_RevertIf_MintIfPaymentToContracts() external {
        vm.prank(deployer);
        nameServicePayments.transferOwnership(address(this));
        vm.expectRevert("Failed to send Ether.");
        nameServicePayments.mint{value: 1}(address(this), name, 1);
    }

    function test_RenewName(uint256 timeframeAmount) external {
        vm.assume(type(uint256).max / (nameServicePayments.timeframeSize() * 2) > timeframeAmount);
        vm.assume(timeframeAmount > 0);

        nameServicePayments.mint(address(this), name, timeframeAmount);
        vm.expectEmit();
        emit NameRenewed(name);

        Name memory nameData = nameService.getName(name);
        assertEq(nameData.ttl, block.timestamp + nameServicePayments.timeframeSize() * timeframeAmount);
        nameServicePayments.renewName(address(this), name, timeframeAmount);
        nameData = nameService.getName(name);
        assertEq(nameData.ttl, block.timestamp + 2 * nameServicePayments.timeframeSize() * timeframeAmount);
    }

    function test_MintNameIfExpired() external {
        address anotherOwner = address(0x12345);
        vm.assume(anotherOwner != address(this));
        uint256 timeframeAmount = 1;
        nameServicePayments.mint(address(this), name, timeframeAmount);

        vm.warp(block.timestamp + timeframeAmount * nameServicePayments.timeframeSize());

        vm.prank(anotherOwner);
        vm.expectRevert("This name already exists.");
        // Name in grace period
        nameServicePayments.mint(anotherOwner, name, timeframeAmount);

        vm.warp(block.timestamp + nameServicePayments.gracePeriod() + 1);

        vm.prank(anotherOwner);
        nameServicePayments.mint(anotherOwner, name, timeframeAmount);
        Name memory nameData = nameService.getName(name);
        assertEq(nameData.owner, anotherOwner);
    }

    function test_RevertIf_MintIfNotAuthorized(address notAdmin) external {
        vm.assume(address(this) != notAdmin && address(identityManager) != notAdmin);
        vm.expectRevert("You are not an owner.");
        vm.prank(notAdmin);
        nameServicePayments.mint(address(this), name, 1);
    }

    function test_RevertIf_RenewIfNotAuthorized(address notAdmin) external {
        vm.assume(address(this) != notAdmin && address(identityManager) != notAdmin);
        nameServicePayments.mint(address(this), name, 1);
        vm.expectRevert("You are not an owner.");
        vm.prank(notAdmin);
        nameServicePayments.renewName(address(this), name, 1);
    }

    function test_RevertIf_RenewIfPaymentIsNotEnough() external {
        nameServicePayments.mint(address(this), name, 1);

        vm.prank(deployer);
        nameServicePayments.changePrice(1);

        vm.expectRevert("Value below price.");
        nameServicePayments.renewName{value: 0}(address(this), name, 1);
    }

    function test_RevertIf_RenewIfPayerIsNotOwner(address notOwner) external {
        vm.assume(address(this) != notOwner);
        nameServicePayments.mint(address(this), name, 1);

        vm.expectRevert("You are not an owner.");
        vm.prank(notOwner);
        nameServicePayments.renewName(notOwner, name, 1);
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /*tokenId */
        bytes memory /* data */
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
