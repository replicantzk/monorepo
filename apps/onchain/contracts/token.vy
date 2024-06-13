from snekmate.tokens import erc20 as base_token
from snekmate.auth import ownable
from ethereum.ercs import IERC20

initializes: base_token[ownable := ownable]
initializes: ownable
exports: base_token.IERC20

@deploy
def __init__():
    ownable.__init__()
    base_token.__init__("Replicant Token", "REPL", 18, "Replicant Network", "v0.0.1")
