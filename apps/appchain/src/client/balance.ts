import { PrivateKey, PublicKey, UInt64 } from "o1js";
import { ClientAppChain } from "@proto-kit/sdk";
import { resolver } from "./utils";
import { Balances } from "../runtime/balance";

export async function mint(
  client: ClientAppChain<any>,
  signer: PrivateKey,
  amount: number,
): Promise<void> {
  const balances: Balances = await resolver(client, signer, "Balances");
  const tx = await client.transaction(signer.toPublicKey(), () => {
    balances.mint(UInt64.from(amount));
  });

  await tx.sign();
  await tx.send();
}

export async function burn(
  client: ClientAppChain<any>,
  signer: PrivateKey,
  amount: number,
): Promise<void> {
  const balances: Balances = await resolver(client, signer, "Balances");
  const tx = await client.transaction(signer.toPublicKey(), () => {
    balances.burn(UInt64.from(amount));
  });

  await tx.sign();
  await tx.send();
}

export async function transfer(
  client: ClientAppChain<any>,
  signer: PrivateKey,
  address: PublicKey,
  amount: number,
): Promise<void> {
  const balances: Balances = await resolver(client, signer, "Balances");
  const tx = await client.transaction(signer.toPublicKey(), () => {
    balances.transfer(address, UInt64.from(amount));
  });

  await tx.sign();
  await tx.send();
}
