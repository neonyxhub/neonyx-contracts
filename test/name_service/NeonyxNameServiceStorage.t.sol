// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {NeonyxNameServiceStorage, Name} from "contracts/name_service/NeonyxNameServiceStorage.sol";
import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract NeonyxNameServiceStorageTestBase is Test {
    event NameCreated(address indexed owner, string fullName);
    event DefaultNameChanged(address indexed user, string defaultName);

    NeonyxNameServiceStorage internal nameService;
    string internal nameExample = "name";

    function setUp() external {
        nameService = new NeonyxNameServiceStorage();
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes memory /* data */
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

contract NeonyxNameStorageMintTest is NeonyxNameServiceStorageTestBase {
    function test_MintName(uint256 timeToExpiration) external {
        vm.assume(type(uint256).max - block.timestamp >= timeToExpiration);

        assertEq(nameService.getHolderDefaultName(address(this)), "");
        nameService.checkName(nameExample);

        vm.expectEmit();
        emit NameCreated(address(this), nameExample);

        uint256 tokenId = nameService.mintName(nameExample, address(this), timeToExpiration);

        assertEq(nameService.getHolderDefaultName(address(this)), nameExample);
        assertEq(nameService.getNameOwner(nameExample), address(this));

        Name memory nameData = nameService.getName(nameExample);
        assertEq(nameData.owner, address(this));
        assertEq(nameData.tokenId, tokenId);
        assertEq(nameData.ttl, block.timestamp + timeToExpiration);
    }

    function test_RevertIf_MintNameWithDots() external {
        vm.expectRevert("There should be no dots in the name");
        nameService.mintName(".", address(this), 12345);
    }

    function test_RevertIf_MintNameWithSpaces() external {
        vm.expectRevert("There should be no spaces in the name");
        nameService.mintName(" ", address(this), 12345);
    }

    function test_RevertIf_MintEmptyName() external {
        vm.expectRevert("You can't mint empty name");
        nameService.mintName("", address(this), 12345);
    }

    function test_RevertIf_MintNameByNotAdmin(address notOwner) external {
        vm.assume(address(this) != notOwner);
        bytes memory revertMessage = abi.encodePacked(
            "AccessControl: account ",
            Strings.toHexString(notOwner),
            " is missing role ",
            Strings.toHexString(uint256(nameService.ADMIN_ROLE()), 32)
        );
        vm.expectRevert(revertMessage);
        vm.prank(notOwner);
        nameService.mintName("", address(this), 12345);
    }

    function test_MintDefaultNameSetsOnlyIfNotSet(uint256 timeToExpiration) external {
        vm.assume(type(uint256).max - block.timestamp >= timeToExpiration);
        string memory anotherName = "othername";

        assertEq(nameService.getHolderDefaultName(address(this)), "");
        nameService.mintName(nameExample, address(this), timeToExpiration);
        assertEq(nameService.getHolderDefaultName(address(this)), nameExample);
        nameService.mintName(anotherName, address(this), timeToExpiration);
        assertEq(nameService.getHolderDefaultName(address(this)), nameExample);
    }

    function test_MintNameIfExpired() external {
        uint256 timeToExpiration = 12345;
        uint256 firstTokenId = nameService.mintName(nameExample, address(this), timeToExpiration);

        Name memory nameData = nameService.getName(nameExample);
        assertEq(nameData.owner, address(this));
        assertEq(nameData.tokenId, firstTokenId);
        assertEq(nameData.ttl, block.timestamp + timeToExpiration);

        vm.warp(block.timestamp + timeToExpiration + 1);

        uint256 secondTokenId = nameService.mintName(nameExample, address(this), timeToExpiration);
        assertTrue(firstTokenId != secondTokenId);

        nameData = nameService.getName(nameExample);
        assertEq(nameData.owner, address(this));
        assertEq(nameData.tokenId, secondTokenId);
        assertEq(nameData.ttl, block.timestamp + timeToExpiration);
    }
}

contract NeonyxNameStorageOtherTest is NeonyxNameServiceStorageTestBase {
    function test_GetNameOwnerIfExpired() external {
        uint256 timeToExpiration = 12345;
        nameService.mintName(nameExample, address(this), timeToExpiration);
        assertEq(nameService.getNameOwner(nameExample), address(this));
        vm.warp(block.timestamp + timeToExpiration + 1);
        assertEq(nameService.getNameOwner(nameExample), address(0));
    }

    function test_IncreaseTtlIfNotExpired() external {
        uint256 timeToExpiration = 12345;
        nameService.mintName(nameExample, address(this), timeToExpiration);

        Name memory nameData = nameService.getName(nameExample);
        uint256 blockTimestampBeforeWarp = block.timestamp;
        assertEq(nameData.ttl, block.timestamp + timeToExpiration);

        vm.warp(block.timestamp + 10);

        nameService.increaseTtl(nameExample, timeToExpiration);
        nameData = nameService.getName(nameExample);
        assertEq(nameData.ttl, blockTimestampBeforeWarp + 2 * timeToExpiration);
    }

    function test_IncreaseTtlIfExpired() external {
        uint256 timeToExpiration = 12345;
        nameService.mintName(nameExample, address(this), timeToExpiration);

        Name memory nameData = nameService.getName(nameExample);
        assertEq(nameData.ttl, block.timestamp + timeToExpiration);

        vm.warp(block.timestamp + timeToExpiration + 10);

        nameService.increaseTtl(nameExample, timeToExpiration);

        nameData = nameService.getName(nameExample);
        assertEq(nameData.ttl, block.timestamp + timeToExpiration);
    }

    function test_RevertIf_EditDefaultNameIfNotMinted() external {
        vm.expectRevert("You do not own the selected name");
        nameService.editDefaultName(nameExample);
    }

    function test_EditDefaultName() external {
        uint256 timeToExpiration = 12345;
        string memory baseName = "name123";

        nameService.mintName(nameExample, address(this), timeToExpiration);
        assertEq(nameService.getHolderDefaultName(address(this)), nameExample);

        nameService.mintName(baseName, address(this), timeToExpiration);
        assertEq(nameService.getHolderDefaultName(address(this)), nameExample);

        nameService.editDefaultName(baseName);
        assertEq(nameService.getHolderDefaultName(address(this)), baseName);
    }

    function test_SupportsInterface() external {
        assertTrue(nameService.supportsInterface(type(IAccessControl).interfaceId));
    }

    function test_SupportsInterfaceIfNot() external {
        assertFalse(nameService.supportsInterface(bytes4(0x0)));
    }

    function test_BeforeTokenTransfer() external {
        uint256 timeToExpiration = 12345;
        address receiver = address(0x12345);
        uint256 tokenId = nameService.mintName(nameExample, address(this), timeToExpiration);

        assertEq(nameService.getHolderDefaultName(address(this)), nameExample);
        assertEq(nameService.getHolderDefaultName(receiver), "");

        nameService.transferFrom(address(this), receiver, tokenId);

        assertEq(nameService.getHolderDefaultName(address(this)), "");
        assertEq(nameService.getHolderDefaultName(receiver), nameExample);
        assertEq(nameService.getNameOwner(keccak256(abi.encodePacked(nameExample))), receiver);
    }

    function test_GetNameHash() external {
        assertEq(nameService.getNameHash(nameExample), keccak256(abi.encodePacked(nameExample)));
    }
}
