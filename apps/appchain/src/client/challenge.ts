import { CircuitString, Field, PrivateKey, UInt64 } from "o1js";
import { ClientAppChain } from "@proto-kit/sdk";
import { hashPoseidon, hashSha } from "sdk";
import { Challenges } from "../runtime/challenges";
import { preimageProgram } from "../runtime/utils";
import { resolver } from "./utils";

export async function generatePreimageProof(preimage: string, target: Field) {
  const hash = CircuitString.fromString(hashSha(preimage));
  return await preimageProgram.confirm(target, hash);
}

export async function submit(
  client: ClientAppChain<any>,
  signer: PrivateKey,
  input: string,
  reward: number = 0,
  durationBlocks: number = 30,
): Promise<Field> {
  const confirmations: Confirmations = await resolver(
    client,
    signer,
    "Confirmations",
  );
  const id = hashPoseidon(input);
  const tx = await client.transaction(signer.toPublicKey(), () => {
    confirmations.submit(id, UInt64.from(reward), UInt64.from(durationBlocks));
  });

  await tx.sign();
  await tx.send();

  return id;
}

export async function confirm(
  client: ClientAppChain<any>,
  signer: PrivateKey,
  input: string,
  result: string,
): Promise<void> {
  const confirmations: Confirmations = await resolver(
    client,
    signer,
    "Confirmations",
  );
  const resultHash = hashPoseidon(result);
  const proof = await generatePreimageProof(result, resultHash);
  const id = hashPoseidon(input);
  const tx = await client.transaction(signer.toPublicKey(), () => {
    confirmations.confirm(id, resultHash, proof);
  });

  await tx.sign();
  await tx.send();
}

export async function claim(
  client: ClientAppChain<any>,
  signer: PrivateKey,
  input: string,
): Promise<void> {
  const confirmations: Confirmations = await resolver(
    client,
    signer,
    "Confirmations",
  );
  const id = hashPoseidon(input);
  const tx = await client.transaction(signer.toPublicKey(), () => {
    confirmations.claim(id);
  });

  await tx.sign();
  await tx.send();
}
