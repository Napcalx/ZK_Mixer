//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "@forge-std/Test.sol";
import {Mixer, IVerifier} from "../src/Mixer.sol";
import {IncrementalMerkleTree, Poseidon2} from "../src/IncrementalMerkleTree.sol";
import {HonkVerifier} from "../src/Verifier.sol";

contract MixerTest is Test {
    Mixer public mixer;
    HonkVerifier public verifier;
    Poseidon2 public hasher;

    address public recipient = makeAddr("recipient");

    function setUp() public {
        verifier = new HonkVerifier();

        hasher = new Poseidon2();
        mixer = new Mixer(verifier, hasher, 20);
    }

    function _getCommitment()
        internal
        returns (bytes32 _commitment, bytes32 _nullifier, bytes32 _secret)
    {
        string[] memory inputs = new string[](3);
        inputs[0] = "npx";
        inputs[1] = "tsx";
        inputs[2] = "js-scripts/generateCommitment.ts";

        bytes memory result = vm.ffi(inputs);

        (_commitment, _nullifier, _secret) = abi.decode(
            result,
            (bytes32, bytes32, bytes32)
        );
        return (_commitment, _nullifier, _secret);
    }

    function testMakeDeposit(
        bytes32 _commitment,
        bytes32 _nullifier,
        bytes32 _secret
    ) public {
        (
            bytes32 _commitment,
            bytes32 _nullifier,
            bytes32 _secret
        ) = _getCommitment();
        console.log("Commitment from Ts script");
        console.logBytes32(_commitment);

        vm.expectEmit(true, false, false, true);
        emit Mixer.Deposit(_commitment, 0, block.timestamp);

        mixer.deposit{value: mixer.DENOMINATION()}(_commitment);
    }

    function testMakeWithdrawal() public {
        (
            bytes32 _commitment,
            bytes32 _nullifier,
            bytes32 _secret
        ) = _getCommitment();
        vm.expectEmit(true, false, false, true);
        emit Mixer.Deposit(_commitment, 0, block.timestamp);
        mixer.deposit{value: mixer.DENOMINATION()}(_commitment);

        address recipient = msg.sender;
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = _commitment;
        (bytes memory _proof, bytes32[] memory _publicInputs) = _getProof(
            _nullifier,
            _secret,
            recipient,
            leaves
        );

        assertTrue(
            verifier.verify(_proof, _publicInputs),
            "Proof Verification failed"
        );

        assertEq(recipient.balance, 0, "Recipient Inital balance should be 0");
        assertEq(
            address(mixer).balance,
            mixer.DENOMINATION(),
            "Mixer Inital balance incorrect after deposit"
        );

        mixer.withdraw(
            _proof,
            _publicInputs[0],
            _publicInputs[1],
            payable(address(uint160(uint256(_publicInputs[2]))))
        );

        assertEq(
            recipient.balance,
            mixer.DENOMINATION(),
            "Recipient did not receive funds"
        );
        assertEq(
            address(mixer).balance,
            0,
            "Mixer balance not zero after withdrawal"
        );
    }

    function _getProof(
        bytes32 _nullifier,
        bytes32 _secret,
        address _recipient,
        bytes32[] memory _leaves
    ) internal returns (bytes memory _proof, bytes32[] memory _publicInputs) {
        string[] memory inputs = new string[](6 + _leaves.length);
        inputs[0] = "npx";
        inputs[1] = "tsx";
        inputs[2] = "js-scripts/generateProof.ts";
        inputs[3] = vm.toString(_nullifier);
        inputs[4] = vm.toString(_secret);
        // Convert address to uint160, then uint256 (padding), then bytes32, then string
        inputs[5] = vm.toString(bytes32(uint256(uint160(_recipient))));
        for (uint i = 0; i < _leaves.length; i++) {
            inputs[6 + i] = vm.toString(_leaves[i]);
        }
        bytes memory result = vm.ffi(inputs);
        (bytes memory _proof, bytes32[] memory _publicInputs) = abi.decode(
            result,
            (bytes, bytes32[])
        );
    }

    function testAnotherAddressSendProof() public {
        (
            bytes32 _commitment,
            bytes32 _nullifier,
            bytes32 _secret
        ) = _getCommitment();
        mixer.deposit{value: mixer.DENOMINATION()}(_commitment);
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = _commitment;
        (bytes memory _proof, bytes32[] memory _publicInputs) = _getProof(
            _nullifier,
            _secret,
            recipient,
            leaves
        );
        assertTrue(verifier.verify(_proof, _publicInputs));

        address _attackerAddress = makeAddr("attacker");
        vm.prank(_attackerAddress);
        vm.expectRevert();
        mixer.withdraw(
            _proof,
            _publicInputs[0],
            _publicInputs[1],
            payable(_attackerAddress)
        );
    }
}
