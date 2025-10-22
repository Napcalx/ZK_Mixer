use poseidon::poseidon2;

pub fn compute_merkle_root(leaf: Field, proof: [Field; 20], is_even: [bool; 20]) -> Field {
    let mut current_hash: Field = leaf;

    for i in 0..20 {
        let (left_input, right_input): (Field, Field) = if is_even[i] {
            (current_hash, proof[i])
        } else {
            (proof[i], current_hash)
        };
        current_hash = poseidon2::Poseidon2::hash([left_input, right_input], 2);
    }
    current_hash
}
