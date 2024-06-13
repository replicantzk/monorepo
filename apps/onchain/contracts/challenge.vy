from snekmate.auth import ownable
import interfaces.verifier_leaf as VerifierLeaf
import interfaces.verifier_tree as VerifierTree

initializes: ownable

struct Challenge:
    attestor: address
    input_: bytes32
    output_: bytes32

verifierLeaf: VerifierLeaf
verifierTree: VerifierTree

challengeIndex: uint256
challengeMap: HashMap[uint256, Challenge]

@deploy
def __init__():
    ownable.__init__()
