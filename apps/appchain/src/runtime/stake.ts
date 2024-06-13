import { PublicKey, UInt64 } from "o1js";
import {
  runtimeMethod,
  RuntimeModule,
  runtimeModule,
  state,
} from "@proto-kit/module";
import { assert, StateMap } from "@proto-kit/protocol";
import { inject } from "tsyringe";
import { Balances } from "./balance";

interface StakeConfig {}

@runtimeModule()
export class Stake extends RuntimeModule<StakeConfig> {
  public constructor(@inject("Balances") private balances: Balances) {
    super();
  }

  @state() public amounts = StateMap.from<PublicKey, UInt64>(PublicKey, UInt64);
  @state() public locks = StateMap.from<PublicKey, UInt64>(PublicKey, UInt64);

  public _getAmount(address: PublicKey): UInt64 {
    return this.amounts.get(address).orElse(UInt64.from(0));
  }

  public _getLock(address: PublicKey): UInt64 {
    return this.locks.get(address).orElse(UInt64.from(0));
  }

  public _setLock(address: PublicKey, block: UInt64): void {
    this.locks.set(address, block);
  }

  public _stake(amount: UInt64): void {
    const address = this.transaction.sender.value;
    this.balances._burn(address, amount);
    this.amounts.set(address, this._getAmount(address).add(amount));
  }

  public _unstake(amount: UInt64): void {
    const address = this.transaction.sender.value;
    assert(
      this._getLock(address).lessThan(this.network.block.height),
      "stake still locked",
    );
    const currentStake = this._getAmount(address);
    assert(
      currentStake.greaterThanOrEqual(amount),
      "amount exceeds amount staked",
    );
    this.balances._mint(address, amount);
    this.amounts.set(address, currentStake.sub(amount));
  }

  public _lock(address: PublicKey, block: UInt64): void {
    this.locks.set(address, block);
  }

  @runtimeMethod()
  public stake(amount: UInt64): void {
    this._stake(amount);
  }

  @runtimeMethod()
  public unstake(amount: UInt64): void {
    this._unstake(amount);
  }
}
