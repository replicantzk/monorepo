from snekmate.auth import ownable
from ethereum.ercs import IERC20
import interfaces.stake as IStake

initializes: ownable

struct Attest:
    _hash: bytes32
    requiredStake: uint256
    reward: uint256
    claimed: bool

ATTESTATIONS_SIZE: constant(uint8) = 8

owner: address
token: IERC20
stake: IStake
reward: uint256
attestations: HashMap[address, Attest[ATTESTATIONS_SIZE]]
attestationsIndex: HashMap[address, uint8]

@deploy
def __init__():
    ownable.__init__()

@external
def setReward(reward: uint256):
    assert self.owner == msg.sender, "only owner can set reward"

@external
def post(attestor: address, _hash: bytes32, requiredStake: uint256, reward: uint256):
    assert self.owner == msg.sender, "only owner can post"
    newIndex: uint8 = self.attestationsIndex[attestor] + 1
    self.attestationsIndex[attestor] = newIndex
    attestation: Attest = Attest(_hash=_hash, requiredStake=requiredStake, reward=reward, claimed=False)
    self.attestations[attestor][newIndex] = attestation
    extcall self.token.approve(msg.sender, self.reward)
    extcall self.token.transferFrom(msg.sender, self, self.reward)

@external
def attest(index: uint8):
    attestation: Attest = self.attestations[msg.sender][index]
    stakeAmount: uint256 = self.stake.getStakeAmount(msg.sender)
    assert stakeAmount >= attestation.requiredStake, "not enough stake"
    assert attestation.claimed == False, "already claimed"
    attestation.claimed = True

    extcall self.stake.lock(msg.sender)
    extcall self.token.transfer(self, msg.sender)
