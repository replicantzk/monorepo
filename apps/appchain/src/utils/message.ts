import { PrivateKey } from "o1js";
import { SignedLegacy } from "o1js/dist/node/mina-signer/src/TSTypes";
import Client from "mina-signer";
import { NetworkId } from "mina-signer";
import { z } from "zod";

export const messageSchema = z.object({
  publicKey: z.string(),
  timestamp: z.number(),
  model: z.string(),
  input: z.any(),
});

export type Message = z.infer<typeof messageSchema>;

export type MinaSignatureSchema = SignedLegacy<string>;

export function messageEncode(
  privateKey: PrivateKey,
  model: string,
  input: any,
  schema: z.Schema<Message>,
  network: NetworkId = "testnet",
): object {
  let client = new Client({ network: network });
  try {
    schema.parse(input);
    const message = {
      publicKey: privateKey.toPublicKey().toBase58(),
      timestamp: Date.now(),
      model: model,
      input: input,
    };
    const signedMessage = client.signMessage(
      JSON.stringify(message),
      privateKey.toBase58(),
    );
    return signedMessage;
  } catch (e) {
    const error_message = "Error encoding message: " + e;
    console.log(error_message);
    throw new Error(error_message);
  }
}
