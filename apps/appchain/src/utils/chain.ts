import { Experimental, Field, CircuitString, Poseidon } from "o1js";
import { assert, Option } from "@proto-kit/protocol";
import { PrivateKey } from "o1js";
import { ClientAppChain, InMemorySigner } from "@proto-kit/sdk";
import { leafProgram } from "../runtime/attest";

export function unwrap<T>(
  option: Option<T>,
  message: string | undefined = undefined,
  default_: T | undefined = undefined,
): T {
  const isSome = option.isSome;
  const messageOut = message ? message : "option result not found";
  if (default_ === undefined && !isSome.toBoolean()) {
    assert(isSome.not(), messageOut);
  }

  let result: T = default_ !== undefined ? default_ : option.value;

  return result;
}

export const preimageProgram = Experimental.ZkProgram({
  name: "preimage",
  publicInput: Field,

  methods: {
    confirm: {
      privateInputs: [CircuitString],
      method: (publicInput: Field, preimage: CircuitString) => {
        Poseidon.hash(preimage.toFields()).assertEquals(publicInput);
      },
    },
  },
});

export class PreimageProof extends Experimental.ZkProgram.Proof(
  preimageProgram,
) {}

export async function globalCompile() {
  // const absolutePath = path.resolve(cacheDir);
  // if (!fs.existsSync(absolutePath)) {
  //   throw new Error(`Directory does not exist: ${absolutePath}`);
  // }
  // const cache: Cache = Cache.FileSystem(absolutePath);
  await leafProgram.compile();
  await preimageProgram.compile();
}

export async function resolver(
  client: ClientAppChain<any>,
  privateKey: PrivateKey,
  moduleName: string,
): Promise<any> {
  await client.start();
  const inMemorySigner = new InMemorySigner();

  client.registerValue({
    Signer: inMemorySigner,
  });
  const resolvedInMemorySigner = client.resolve("Signer") as InMemorySigner;
  resolvedInMemorySigner.config = { signer: privateKey };

  return client.runtime.resolve(moduleName);
}
