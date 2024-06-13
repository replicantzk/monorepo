use dep::std::hash::poseidon2;

fn main(
    input: pub [Field; 32],
    output: pub [Field; 32],
    leaf: pub Field,
) {
    let mut concat = [0; 64];
    for i in 0 .. 64 {
       if i < 32 {
           concat[i] = input[i];
       } else {
           concat[i] = output[i - 32];
       }
    }
    let hash = poseidon2::Poseidon2::hash(concat, 64);
    assert(hash == leaf, "input and output do not create the leaf");
}

#[test]
fn test_main() {
}
