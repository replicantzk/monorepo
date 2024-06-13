import { PublicKey, UInt64 } from "o1js";
import {
  runtimeMethod,
  RuntimeModule,
  runtimeModule,
  state,
} from "@proto-kit/module";
import { assert, StateMap } from "@proto-kit/protocol";

interface BalancesConfig {}

@runtimeModule()
export class Balances extends RuntimeModule<BalancesConfig> {
  @state() public amounts = StateMap.from<PublicKey, UInt64>(PublicKey, UInt64);

  public _getAmount(address: PublicKey): UInt64 {
    return this.amounts.get(address).orElse(UInt64.from(0));
  }

  public _mint(address: PublicKey, amount: UInt64): void {
    const currentBalance = this._getAmount(address);
    const newBalance = currentBalance.add(amount);
    this.amounts.set(address, newBalance);
  }

  public _burn(address: PublicKey, amount: UInt64): void {
    const currentBalance = this._getAmount(address);
    const newBalance = currentBalance.sub(amount);
    const newBalanceNonzero = newBalance.greaterThanOrEqual(UInt64.from(0));
    assert(newBalanceNonzero, "balance would be negative");
    this.amounts.set(address, newBalance);
  }

  public _transfer(from: PublicKey, to: PublicKey, amount: UInt64) {
    const fromBalance = this._getAmount(from);
    const sufficientBalance = fromBalance.greaterThanOrEqual(amount);
    assert(sufficientBalance, "insufficient balance to transfer");
    this._burn(from, amount);
    this._mint(to, amount);
  }

  // Testing
  @runtimeMethod()
  public mint(amount: UInt64): void {
    this._mint(this.transaction.sender.value, amount);
  }

  // Testing
  @runtimeMethod()
  public burn(amount: UInt64): void {
    this._burn(this.transaction.sender.value, amount);
  }

  @runtimeMethod()
  public transfer(address: PublicKey, amount: UInt64): void {
    this._transfer(this.transaction.sender.value, address, amount);
  }
}
