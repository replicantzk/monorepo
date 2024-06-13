import { PrivateKey, UInt64 } from "o1js";
import { log } from "@proto-kit/common";
import { TestingAppChain } from "@proto-kit/sdk";
import { Balance } from "../src/runtime/balances";

log.setLevel("ERROR");

describe("balances", () => {
  it("should demonstrate how balances work", async () => {
    const appChain = TestingAppChain.fromRuntime({
      modules: {
        Balance,
      },
    });

    appChain.configurePartial({
      Runtime: {
        Balances: {},
      },
    });

    await appChain.start();

    const alicePrivateKey = PrivateKey.random();
    const alice = alicePrivateKey.toPublicKey();

    appChain.setSigner(alicePrivateKey);

    const balances = appChain.runtime.resolve("Balance");

    const tx1 = await appChain.transaction(alice, () => {
      balances._mint(alice, UInt64.from(1000));
    });

    await tx1.sign();
    await tx1.send();

    const block = await appChain.produceBlock();

    const balance = await appChain.query.runtime.Balance.balances.get(alice);

    expect(block?.transactions[0].status.toBoolean()).toBe(true);
    expect(balance?.toBigInt()).toBe(1000n);
  }, 1_000_000);
});
