import { PrivateKey, PublicKey, UInt64 } from "o1js";
import { ClientAppChain } from "@proto-kit/sdk";
import { resolver } from "./utils";
import Stake from "../runtime/stake";

export async function stake(
  client: ClientAppChain<any>,
  signer: PrivateKey,
  amount: number,
): Promise<void> {
  const stake: Stake = await resolver(client, signer, "Stake");
  const tx = await client.transaction(signer.toPublicKey(), () => {
    stake.stake(UInt64.from(amount));
  });

  await tx.sign();
  await tx.send();
}
