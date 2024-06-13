from snekmate.auth import ownable
from ethereum.ercs import IERC20

initializes: ownable

struct Stake:   
    amount: uint256
    unlock: uint256

REWARD_SIZE: public(constant(uint256)) = 8

owner: address
token: IERC20
canLock: address
canSlash: address
stakeDuration: uint256
stakeMap: HashMap[address, Stake]

@deploy
def __init__(token: IERC20, stakeDuration: uint256, canLock: address,  canSlash: address):
    ownable.__init__()
    self.stakeDuration = stakeDuration
    self.canLock = canLock
    self.canSlash = canSlash

@external
def setCanLock(canLock: address):
    assert self.owner == msg.sender, "only owner can set canLock addresses"
    self.canLock = canLock

@external
def setCanSlash(canSlash: address):
    assert self.owner == msg.sender, "only owner can set canSlash addresses"
    self.canSlash = canSlash

@external
def setStakeDuration(duration: uint256):
    assert self.owner == msg.sender, "only owner can set stake duration"
    self.stakeDuration = duration

@external
def getStakeAmount(staker: address) -> uint256:
    return self.stakeMap[staker].amount

@external
def stake_(amount: uint256):
    balance_: uint256 = staticcall self.token.balanceOf(msg.sender)
    assert amount <= balance_, "cannot stake more than balance"

    extcall self.token.approve(msg.sender, amount)
    extcall self.token.transferFrom(msg.sender, self, amount)
    self._addStakeAmount(msg.sender, amount)

@external
def unstake(amount: uint256):
    stake: Stake = self.stakeMap[msg.sender]
    
    assert amount <= stake.amount, "cannot unstake more than staked"
    assert block.timestamp >= stake.unlock, "cannot unstake before unlock"

    extcall self.token.transfer(msg.sender, amount)

    self._removeStakeAmount(msg.sender, amount)

@external
def lock(staker: address):
    assert msg.sender == self.canLock, "only canLock addresses can lock"
    stake: Stake = self.stakeMap[staker]
    stake.unlock += self.stakeDuration

@external
def slash(staker: address, amount: uint256, reward: address[REWARD_SIZE]):
    assert msg.sender == self.canSlash, "only canSlash addresses can slash"
    stake: Stake = self.stakeMap[staker]
    assert amount <= stake.amount, "cannot slash more than staked"

    amountPerReward: uint256 = amount // REWARD_SIZE

    for i: uint256 in range(REWARD_SIZE):
        extcall self.token.transfer(reward[i], amountPerReward)

    self._removeStakeAmount(staker, amount)

@internal
def _addStakeAmount(staker: address, amount: uint256):
    stake: Stake = self.stakeMap[msg.sender]
    if stake.amount == empty(uint256):
        stake = Stake(amount=amount, unlock=block.timestamp + self.stakeDuration)
        self.stakeMap[msg.sender] = stake
    else:
        stake.amount += amount
        stake.unlock = block.timestamp + self.stakeDuration

@internal
def _removeStakeAmount(staker: address, amount: uint256):
    stake: Stake = self.stakeMap[staker]

    if stake.amount - amount > 0:
        stake.amount -= amount
    else:
        stake.amount = 0
