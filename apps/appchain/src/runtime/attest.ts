import {
  PublicKey,
  Field,
  Provable,
  Struct,
  UInt64,
  Bool,
  MerkleWitness,
  Experimental,
  CircuitString,
  Poseidon,
} from "o1js";
import {
  runtimeMethod,
  RuntimeModule,
  runtimeModule,
  state,
} from "@proto-kit/module";
import { assert, StateMap } from "@proto-kit/protocol";
import { inject } from "tsyringe";
import { Balances } from "./balance";
import { Stake } from "./stake";
import { Challenges } from "./challenge";
import { PreimageProof } from "../utils/chain";

export const ATTEST_LENGTH = 8;
export const ATTEST_TREE_SIZE = 64;

export class Leaf extends Struct({
  reqHash: Field,
  resHash: Field,
  leaf: Field,
}) {}

export const leafProgram = Experimental.ZkProgram({
  name: "leaf",
  publicInput: Leaf,

  methods: {
    confirm: {
      privateInputs: [CircuitString, CircuitString],
      method: (publicInput: Leaf, req: CircuitString, res: CircuitString) => {
        const reqHash = Poseidon.hash(req.toFields());
        const resHash = Poseidon.hash(res.toFields());
        publicInput.reqHash.assertEquals(reqHash);
        publicInput.resHash.assertEquals(resHash);
        const leaf = Poseidon.hash([reqHash, resHash]);
        publicInput.leaf.assertEquals(leaf);
      },
    },
  },
});

export class leafProof extends Experimental.ZkProgram.Proof(leafProgram) {}

export class ChallengeMerkleWitness extends MerkleWitness(ATTEST_TREE_SIZE) {}

export class Attestations extends Struct({
  hashes: Provable.Array(Field, ATTEST_LENGTH),
}) {
  public static empty(): Attestations {
    const hashes = new Array(ATTEST_LENGTH).fill(Field(0));
    return new Attestations({
      hashes: hashes,
    });
  }

  public update(state: Field) {
    for (let i = 0; i < ATTEST_LENGTH; i++) {
      this.hashes[i + 1] = this.hashes[i];
    }

    this.hashes[0] = state;
  }
}

export class Nullifier extends Struct({
  address: PublicKey,
  state: Field,
}) {}

interface InferenceConfig {
  claimReward: UInt64;
  challengeReward: UInt64;
  challengePeriod: UInt64;
}

@runtimeModule()
export class Inference extends RuntimeModule<InferenceConfig> {
  public constructor(
    @inject("Balances") private balances: Balances,
    @inject("Stake") private stake: Stake,
    @inject("Challenges") private challenges: Challenges,
  ) {
    super();
  }

  @state() public attestations = StateMap.from<PublicKey, Attestations>(
    PublicKey,
    Attestations,
  );
  @state() public nullifiers = StateMap.from<Nullifier, Bool>(Nullifier, Bool);

  public _getAttestation(address: PublicKey): Attestations {
    return this.attestations.get(address).orElse(Attestations.empty());
  }

  public _setAttestation(address: PublicKey, hashes: Field[]): void {
    this.attestations.set(address, new Attestations({ hashes: hashes }));
  }

  public _updateAttestation(address: PublicKey, state: Field): void {
    const attestations = this._getAttestation(address);
    attestations.update(state);
    this.attestations.set(address, attestations);
  }

  public _checkNullifier(
    address: PublicKey,
    state: Field,
    raiseIfExists: boolean,
  ): void {
    const nullifier = new Nullifier({
      address: address,
      state: state,
    });
    const nullifierOption = this.nullifiers.get(nullifier);
    raiseIfExists
      ? assert(nullifierOption.isSome, "nullifer exists")
      : assert(nullifierOption.isSome.not(), "nullifer does not exist");
  }

  public _setNullifier(address: PublicKey, state: Field): void {
    const nullifier = new Nullifier({
      address: address,
      state: state,
    });

    this.nullifiers.set(nullifier, Bool(false));
  }

  @runtimeMethod()
  public attest(address: PublicKey, state: Field): void {
    this._updateAttestation(address, state);
  }

  @runtimeMethod()
  public claim(state: Field, proof: PreimageProof): void {
    proof.verify();
    proof.publicInput.assertEquals(state);
    const address = this.transaction.sender.value;
    this._checkNullifier(address, state, true);
    const attestations = this._getAttestation(address);
    // TODO: Sketch
    Bool(attestations.hashes.includes(state)).assertTrue();
    this.balances._mint(address, this.config.claimReward);
    this._setNullifier(address, state);
  }

  @runtimeMethod()
  public challenge(
    address: PublicKey,
    attestation: Field,
    reqHash: Field,
    resHash: Field,
    leaf: Field,
    witness: ChallengeMerkleWitness,
    proof: leafProof,
  ): void {
    proof.verify();
    proof.publicInput.reqHash.assertEquals(reqHash);
    proof.publicInput.resHash.assertEquals(resHash);
    proof.publicInput.leaf.assertEquals(leaf);
    const attestations = this._getAttestation(address);
    Bool(attestations.hashes.includes(attestation)).assertTrue();
    const root = witness.calculateRoot(leaf);
    root.assertEquals(attestation);
    this.challenges._createChallenge(
      reqHash,
      resHash,
      address,
      this.config.challengePeriod,
      this.config.challengeReward,
    );
  }

  @runtimeMethod()
  public reset(): void {
    this.attestations.set(this.transaction.sender.value, Attestations.empty());
  }
}
