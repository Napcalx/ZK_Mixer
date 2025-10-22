//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IVerifier} from "./Verifier.sol";
import {IncrementalMerkleTree, Poseidon2} from "./IncrementalMerkleTree.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Mixer - Adaptation of TornadoCash
 * @author CX-Kariiwe
 * @notice This smart contract is a simplified and modified version of the Tornado Cash protocol,
 * developed purely for educational purposes as part of a zero-knowledge proofs course.
 * @dev The original design and cryptographic structure are inspired and modified from Tornado Cash:
 * https://github.com/tornadocash/tornado-core
 * @notice Do not deploy this contract to mainnet or use for handling real funds.
 * This contract is unaudited and intended for demonstration only.
 */
contract Mixer is IncrementalMerkleTree, ReentrancyGuard {
    IVerifier public immutable i_verifier;

    /*//////////////////////////////////////////////////////////////
                                MAPPINGS
    //////////////////////////////////////////////////////////////*/
    mapping(bytes32 => bool) public s_commitments;
    mapping(bytes32 => bool) public s_usedNulifiers;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 public constant DENOMINATION = 0.01 ether;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Mixer__InvalidDepositAmount(
        uint256 amountSent,
        uint256 expectedAmount
    );
    error Mixer__WithdrawalFailed(address recipient, uint256 amount);
    error Mixer__CommitmentAlreadySubmitted(bytes32 commitmments);
    error Mixer__UnknownRoot(bytes32 root);
    error Mixer__InvalidZKProof();
    error Mixer__FeeExceedsDepositValue(uint256 expected, uint256 actual);
    error Mixer__NulifierAlreadyUsed(bytes32 nulifierHash);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event Deposit(
        bytes32 indexed commitment,
        uint32 indexed insertedIndex,
        uint256 timestamp
    );
    event Withdrawal(
        address indexed recipient,
        bytes32 indexed nulifierHash,
        uint256 timestamp
    );

    constructor(
        IVerifier _verifier,
        Poseidon2 _hasher,
        uint32 _merkleTreeDepth
    ) IncrementalMerkleTree(_merkleTreeDepth, _hasher) {
        i_verifier = _verifier;
    }

    function deposit(bytes32 _commitment) external payable nonReentrant {
        if (s_commitments[_commitment]) {
            revert Mixer__CommitmentAlreadySubmitted(_commitment);
        }
        if (msg.value != DENOMINATION) {
            revert Mixer__InvalidDepositAmount(msg.value, DENOMINATION);
        }
        uint32 insertedIndex = _insert(_commitment);
        s_commitments[_commitment] = true;

        emit Deposit(_commitment, insertedIndex, block.timestamp);
    }

    /// @notice Withdraw funds from the mixer in a private way
    /// @param _proof the proof that the user has the right to withdraw (they know a valid commitment)
    /// @param _merkleRoot the root that was used in the proof matches the root on-chain
    /// @param _nullifierHash the hash of the nullifier to prevent double spending
    /// @param recipient The address that will receive the funds
    /// @dev The proof is generated off-chain using the script
    function withdraw(
        bytes calldata _proof,
        bytes32 _merkleRoot,
        bytes32 _nullifierHash,
        address payable recipient
    ) external nonReentrant {
        // 1. check that the root that was used in the proof matches the root on-chain
        // 2. check that the nullifier has not yet been used to prevent double spending
        // 3. check that the proof is valid by calling the verifier contract
        // 4. send them the funds

        if (s_usedNulifiers[_nullifierHash]) {
            revert Mixer__NulifierAlreadyUsed(_nullifierHash);
        }
        if (!IncrementalMerkleTree.isKnownRoot(_merkleRoot)) {
            revert Mixer__UnknownRoot(_merkleRoot);
        }

        bytes32[] memory _publicInputs = new bytes32[](4);
        _publicInputs[0] = _merkleRoot;
        _publicInputs[1] = _nullifierHash;
        _publicInputs[2] = bytes32(uint256(uint160(address(recipient))));
        _publicInputs[3] = bytes32(DENOMINATION);

        bool isValid = i_verifier.verify(_proof, _publicInputs);
        if (!isValid) {
            revert Mixer__InvalidZKProof();
        }

        s_usedNulifiers[_nullifierHash] = true;
        (bool success, ) = recipient.call{value: DENOMINATION}("");
        if (!success) {
            revert Mixer__WithdrawalFailed({
                recipient: recipient,
                amount: DENOMINATION
            });
        }

        emit Withdrawal(recipient, _nullifierHash, block.timestamp);
    }
}
