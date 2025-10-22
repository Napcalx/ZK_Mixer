use poseidon::poseidon2;
mod merkle_tree;

fn main(
    // Public Inputs
    root: pub Field,
    nullifier_hash: pub Field,
    recipient: pub Field,
    // Private Inputs
    nullifier: Field,
    secret: Field,
    merkle_proof: [Field; 20],
    isValid: [bool; 20],
) {
    let commitment: Field = poseidon2::Poseidon2::hash([nullifier, secret], 2);
    let computed_nullifier_hash: Field = poseidon2::Poseidon2::hash([nullifier], 1);
    let computed_root: Field = merkle_tree::compute_merkle_root(commitment, merkle_proof, isValid);
    let recipient_binding = recipient * recipient;

    assert(computed_nullifier_hash == nullifier_hash);
    assert(computed_root == root);
    assert(recipient_binding == recipient * recipient);
}
