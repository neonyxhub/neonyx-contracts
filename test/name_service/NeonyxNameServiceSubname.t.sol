// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {NeonyxNameServiceSubname, Subname} from "contracts/name_service/NeonyxNameServiceSubname.sol";
import {NeonyxNameServiceStorage, Name} from "contracts/name_service/NeonyxNameServiceStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IdentityManager} from "contracts/did/IdentityManager.sol";
import "forge-std/Test.sol";

contract NeonyxNameServiceSubnameTest is Test {
    NeonyxNameServiceStorage internal nameService;
    IdentityManager internal identityManager;
    NeonyxNameServiceSubname internal nameServiceSubname;

    string internal prefix = "name";
    string internal subname = "subname";

    function setUp() external {
        nameService = new NeonyxNameServiceStorage();
        identityManager = new IdentityManager();
        nameServiceSubname = new NeonyxNameServiceSubname(nameService, identityManager);
    }

    modifier prefixMinted() {
        nameService.mintName(prefix, address(this), 1e10);
        _;
    }

    function test_AddSubname() external prefixMinted {
        Subname memory subnameData = nameServiceSubname.resolveSubname(string(abi.encodePacked(prefix, ".", subname)));
        assertEq(subnameData.owner, address(0));

        nameServiceSubname.addSubname(address(this), subname, prefix);

        subnameData = nameServiceSubname.resolveSubname(string(abi.encodePacked(prefix, ".", subname)));
        assertEq(subnameData.owner, address(this));
    }

    function test_AddSameSubname() external prefixMinted {
        Subname memory subnameData = nameServiceSubname.resolveSubname(string(abi.encodePacked(prefix, ".", subname)));
        assertEq(subnameData.owner, address(0));

        nameServiceSubname.addSubname(address(this), subname, prefix);

        subnameData = nameServiceSubname.resolveSubname(string(abi.encodePacked(prefix, ".", subname)));
        assertEq(subnameData.owner, address(this));

        nameServiceSubname.addSubname(address(this), subname, prefix);

        subnameData = nameServiceSubname.resolveSubname(string(abi.encodePacked(prefix, ".", subname)));
        assertEq(subnameData.owner, address(this));
    }

    function test_RevertIf_AddSubnameByNotNameOwner() external {
        vm.expectRevert("You are not prefix owner.");
        nameServiceSubname.addSubname(address(this), subname, prefix);
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
