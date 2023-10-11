// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IdentityManager} from "contracts/did/IdentityManager.sol";
import {ModuleStorage} from "contracts/messanger/ModuleStorage.sol";
import {ClubRegistry, Club} from "contracts/messanger/messanger_units/ClubRegistry.sol";
import {IEAS, AttestationRequest, RevocationRequest} from "eas-contracts/IEAS.sol";
import {EAS, Attestation} from "eas-contracts/EAS.sol";
import {SchemaRegistry, ISchemaResolver} from "eas-contracts/SchemaRegistry.sol";
import {AcceptEveryone} from "contracts/messanger/approval_modules/AcceptEveryone.sol";
import "forge-std/Test.sol";

contract ClubRegistryTestBase is Test {
    event ReputationAdded(address indexed _clubNxid, address indexed _senderNxid, address indexed _receiverNxid);
    event ReputationRemoved(address indexed _clubNxid, address indexed _senderNxid, address indexed _receiverNxid);
    event ReputationAllowed(address indexed _clubNxid);
    event MembershipAllowed(address indexed _clubNxid);
    event MemberAdded(address indexed _clubNxid, address indexed _memberNxid);

    IdentityManager internal identityManager;
    ModuleStorage internal moduleStorage;
    ClubRegistry internal clubRegistry;
    EAS internal eas;
    SchemaRegistry internal schemaRegistry;

    function setUp() public virtual {
        identityManager = new IdentityManager();
        moduleStorage = new ModuleStorage(identityManager);
        schemaRegistry = new SchemaRegistry();
        eas = new EAS(schemaRegistry);
        bytes32 membershipSchema =
            schemaRegistry.register("address clubNxid,address memberNxid", ISchemaResolver(address(0)), true);
        bytes32 reputationSchema = schemaRegistry.register(
            "address clubNxid,address senderNxid,address receiverNxid", ISchemaResolver(address(0)), true
        );
        clubRegistry = new ClubRegistry(moduleStorage, eas, identityManager, membershipSchema, reputationSchema);
    }

    modifier clubMembershipAllowed() {
        clubRegistry.allowMembership(address(this));
        _;
    }

    modifier membershipAndReputationAllowed() {
        clubRegistry.allowMembership(address(this));
        clubRegistry.allowReputation(address(this));
        _;
    }
}

contract ClubRegistryAllowMembershipTest is ClubRegistryTestBase {
    function test_AllowMembership() public {
        Club memory club = clubRegistry.getClub(address(this));
        assertFalse(club.onchainMembershipAllowed);

        vm.expectEmit();
        emit MembershipAllowed(address(this));

        clubRegistry.allowMembership(address(this));

        club = clubRegistry.getClub(address(this));
        assertTrue(club.onchainMembershipAllowed);
    }

    function test_RevertIf_AllowMembershipTwice() public clubMembershipAllowed {
        vm.expectRevert("Membership already allowed.");
        clubRegistry.allowMembership(address(this));
    }
}

contract ClubRegistryAllowReputationTest is ClubRegistryTestBase {
    function test_AllowReputation() public clubMembershipAllowed {
        Club memory club = clubRegistry.getClub(address(this));
        assertFalse(club.onchainReputationAllowed);

        vm.expectEmit();
        emit ReputationAllowed(address(this));

        clubRegistry.allowReputation(address(this));

        club = clubRegistry.getClub(address(this));
        assertTrue(club.onchainReputationAllowed);
    }

    function test_RevertIf_AllowReputationTwice() public membershipAndReputationAllowed {
        vm.expectRevert("Reputation already allowed.");
        clubRegistry.allowReputation(address(this));
    }

    function test_RevertIf_AllowReputationWhileMembershipNotAllowed() public {
        vm.expectRevert("Membership is not allowed.");
        clubRegistry.allowReputation(address(this));
    }
}

contract ClubMembershipTestBase is ClubRegistryTestBase {
    modifier checkMembership(address member) {
        assertFalse(clubRegistry.isMember(address(this), address(member)));
        bytes32 attest_uid = clubRegistry.membership(address(this), address(member));
        assertEq(attest_uid, bytes32(""));
        _;
        assertTrue(clubRegistry.isMember(address(this), address(member)));
        attest_uid = clubRegistry.membership(address(this), address(member));
        Attestation memory membershipAttestation = eas.getAttestation(attest_uid);

        assertEq(membershipAttestation.uid, attest_uid);
        assertEq(membershipAttestation.schema, clubRegistry.membershipSchema());
        assertTrue(membershipAttestation.revocable);
        assertEq(membershipAttestation.data, abi.encode(address(this), member));
        assertEq(membershipAttestation.time, block.timestamp);
        assertEq(membershipAttestation.revocationTime, 0);
        assertEq(membershipAttestation.expirationTime, 0);
        assertEq(membershipAttestation.refUID, bytes32(""));
        assertEq(membershipAttestation.recipient, address(0));
        assertEq(membershipAttestation.attester, address(clubRegistry));
    }

    modifier clubMember(address member) {
        if (!clubRegistry.isMember(address(this), member)) {
            clubRegistry.addMember(address(this), member);
        }
        _;
    }
}

contract ClubRegistryAddMemberTest is ClubMembershipTestBase {
    function test_AddMember(address memberToAdd) external clubMembershipAllowed checkMembership(memberToAdd) {
        vm.expectEmit();
        emit MemberAdded(address(this), memberToAdd);

        clubRegistry.addMember(address(this), memberToAdd);
    }

    function test_RevertIf_AddMemberIfMembershipNotAllowed(address memberToAdd) external {
        vm.expectRevert("Membership is not allowed.");
        clubRegistry.addMember(address(this), memberToAdd);
    }

    function test_RevertIf_AddMemberTwice(address memberToAdd) external clubMembershipAllowed {
        clubRegistry.addMember(address(this), memberToAdd);
        vm.expectRevert("Attestation already exist.");
        clubRegistry.addMember(address(this), memberToAdd);
    }

    function test_AddMemberByNotAdmin(address memberToAdd, address notAdmin) external {
        vm.assume(address(this) != notAdmin && notAdmin != address(identityManager));
        vm.expectRevert("You are not an owner.");
        vm.prank(notAdmin);
        clubRegistry.addMember(address(this), memberToAdd);
    }
}

contract ClubRegistryJoinClubTest is ClubMembershipTestBase {
    function setUp() public override {
        super.setUp();
        AcceptEveryone module = new AcceptEveryone(identityManager);
        moduleStorage.addWhitelistModule(address(this), address(module));
    }

    function test_JoinClub(address memberNxid) external clubMembershipAllowed checkMembership(memberNxid) {
        vm.prank(memberNxid);
        clubRegistry.joinClub(memberNxid, address(this));
    }

    function test_RevertIf_JoinClubIfMembershipNotAllowed(address memberNxid) external {
        vm.expectRevert("Membership is not allowed.");
        vm.prank(memberNxid);
        clubRegistry.joinClub(memberNxid, address(this));
    }

    function test_RevertIf_JoinClubTwice(address memberNxid) external clubMembershipAllowed clubMember(memberNxid) {
        vm.expectRevert("Attestation already exist.");
        vm.prank(memberNxid);
        clubRegistry.joinClub(memberNxid, address(this));
    }

    function test_JoinClubByNotAdmin(address memberNxid, address notAdmin) external clubMembershipAllowed {
        vm.assume(memberNxid != notAdmin && notAdmin != address(identityManager));
        vm.expectRevert("You are not an owner.");
        vm.prank(notAdmin);
        clubRegistry.joinClub(memberNxid, address(this));
    }
}

contract ClubReputationTestBase is ClubMembershipTestBase {
    modifier checkReputation(address member, address reputationSender) {
        assertEq(clubRegistry.getReputation(address(this), address(member)), 0);
        bytes32 attest_uid = clubRegistry.reputationAttests(address(this), reputationSender, member);
        assertEq(attest_uid, bytes32(""));
        _;
        assertEq(clubRegistry.getReputation(address(this), address(member)), 1);
        attest_uid = clubRegistry.reputationAttests(address(this), reputationSender, member);
        Attestation memory membershipAttestation = eas.getAttestation(attest_uid);

        assertEq(membershipAttestation.uid, attest_uid);
        assertEq(membershipAttestation.schema, clubRegistry.reputationSchema());
        assertTrue(membershipAttestation.revocable);
        assertEq(membershipAttestation.data, abi.encode(address(this), reputationSender, member));
        assertEq(membershipAttestation.time, block.timestamp);
        assertEq(membershipAttestation.revocationTime, 0);
        assertEq(membershipAttestation.expirationTime, 0);
        assertEq(membershipAttestation.refUID, bytes32(""));
        assertEq(membershipAttestation.recipient, address(0));
        assertEq(membershipAttestation.attester, address(clubRegistry));
    }

    modifier checkReputationRevoked(address member, address reputationSender) {
        assertEq(clubRegistry.getReputation(address(this), address(member)), 1);
        bytes32 attest_uid = clubRegistry.reputationAttests(address(this), reputationSender, member);
        _;
        Attestation memory membershipAttestation = eas.getAttestation(attest_uid);

        assertEq(membershipAttestation.uid, attest_uid);
        assertEq(membershipAttestation.schema, clubRegistry.reputationSchema());
        assertTrue(membershipAttestation.revocable);
        assertEq(membershipAttestation.data, abi.encode(address(this), reputationSender, member));
        assertEq(membershipAttestation.time, block.timestamp);
        assertEq(membershipAttestation.revocationTime, block.timestamp);
        assertEq(membershipAttestation.expirationTime, 0);
        assertEq(membershipAttestation.refUID, bytes32(""));
        assertEq(membershipAttestation.recipient, address(0));
        assertEq(membershipAttestation.attester, address(clubRegistry));

        bytes32 new_attest_uid = clubRegistry.reputationAttests(address(this), reputationSender, member);
        assertEq(new_attest_uid, bytes32(""));
    }

    modifier reputationAdded(address member, address reputationSender) {
        vm.prank(reputationSender);
        clubRegistry.plusReputation(reputationSender, address(this), member);
        _;
    }
}

contract ClubRegistryPlusReputationTest is ClubReputationTestBase {
    function test_PlusReputation(address sender, address receiver)
        external
        membershipAndReputationAllowed
        clubMember(sender)
        clubMember(receiver)
        checkReputation(receiver, sender)
    {
        vm.expectEmit();
        emit ReputationAdded(address(this), sender, receiver);
        vm.prank(sender);
        clubRegistry.plusReputation(sender, address(this), receiver);
    }

    function test_RevertIf_AddReputationIfNotAllowed(address sender, address receiver) external {
        vm.expectRevert("Reputation is not allowed.");
        vm.prank(sender);
        clubRegistry.plusReputation(sender, address(this), receiver);
    }

    function test_RevertIf_AddReputationTwice(address sender, address receiver)
        external
        membershipAndReputationAllowed
        clubMember(sender)
        clubMember(receiver)
        reputationAdded(receiver, sender)
    {
        vm.expectRevert("Attestation already exist.");
        vm.prank(sender);
        clubRegistry.plusReputation(sender, address(this), receiver);
    }

    function test_RevertIf_AddReputationByNotMember(address sender, address receiver)
        external
        membershipAndReputationAllowed
        clubMember(receiver)
    {
        vm.assume(receiver != sender);
        vm.expectRevert("User is not club member.");
        vm.prank(sender);
        clubRegistry.plusReputation(sender, address(this), receiver);
    }

    function test_RevertIf_AddReputationToNotMember(address sender, address receiver)
        external
        membershipAndReputationAllowed
        clubMember(sender)
    {
        vm.assume(sender != receiver);
        assertEq(clubRegistry.getReputation(address(this), receiver), 0);
        vm.expectRevert("User is not club member.");
        vm.prank(sender);
        clubRegistry.plusReputation(sender, address(this), receiver);
    }

    function test_RevertIf_AddReputationNotAuthorized(address sender, address receiver, address wrongSender) external {
        vm.assume(sender != wrongSender && wrongSender != address(identityManager));
        vm.expectRevert("You are not an owner.");
        vm.prank(wrongSender);
        clubRegistry.plusReputation(sender, address(this), receiver);
    }
}

contract ClubRegistryMinusReputationTest is ClubReputationTestBase {
    function test_MinusReputation(address sender, address receiver)
        external
        membershipAndReputationAllowed
        clubMember(sender)
        clubMember(receiver)
        reputationAdded(receiver, sender)
        checkReputationRevoked(receiver, sender)
    {
        vm.expectEmit();
        emit ReputationRemoved(address(this), sender, receiver);
        vm.prank(sender);
        clubRegistry.minusReputation(sender, address(this), receiver);
    }
}
