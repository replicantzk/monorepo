import * as crypto from "crypto";
import { CircuitString, Field, Poseidon } from "o1js";

export function hashSha(input: string): string {
  return crypto.createHash("sha256").update(input).digest("hex");
}

export function hashPoseidon(input: string): Field {
  return Poseidon.hash(CircuitString.fromString(input).toFields());
}
