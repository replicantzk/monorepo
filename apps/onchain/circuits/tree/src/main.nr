use dep::std::merkle;

#[recursive]
fn main(
    root: pub Field,
    leaf: pub Field,
    index: pub Field,
    path: pub [Field; 64],
) {
    let computed_root = merkle::compute_merkle_root(leaf, index, path);
    assert(computed_root == root);
}

#[test]
fn test_main() {
}
