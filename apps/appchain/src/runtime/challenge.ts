dimport {
  runtimeMethod,
  RuntimeModule,
  runtimeModule,
  state,
} from "@proto-kit/module";
import { assert, StateMap } from "@proto-kit/protocol";
import { Bool, Field, PublicKey, Struct, UInt64 } from "o1js";
import { inject } from "tsyringe";
import { Balances } from "./balance";
import { unwrap, PreimageProof } from "../utils/chain";

export class Challenge extends Struct({
  result: Field,
  submitter: PublicKey,
  deadlineBlocks: UInt64,
  reward: UInt64,
  mostConfirmedHash: Field,
  mostConfirmedCount: UInt64,
  totalConfirmations: UInt64,
}) {}

export class Nullifier extends Struct({
  input: Field,
  address: PublicKey,
}) {}

export class ResultID extends Struct({
  input: Field,
  address: PublicKey,
}) {}

export class ResultCountID extends Struct({
  input: Field,
  result: Field,
}) {}

interface ChallengesConfig {
  slashAmount: UInt64;
}

@runtimeModule()
export class Challenges extends RuntimeModule<ChallengesConfig> {
  public constructor(@inject("Balances") private balances: Balances) {
    super();
  }
  @state() public challenges = StateMap.from<Field, Challenge>(
    Field,
    Challenge,
  );
  @state() public nullifiers = StateMap.from<Nullifier, Bool>(Nullifier, Bool);
  @state() public results = StateMap.from<ResultID, Field>(ResultID, Field);
  @state() public resultCounts = StateMap.from<ResultCountID, UInt64>(
    ResultCountID,
    UInt64,
  );

  public _createChallenge(
    input: Field,
    result: Field,
    submitter: PublicKey,
    durationBlocks: UInt64,
    reward: UInt64,
  ): void {
    const challengeOption = this.challenges.get(input);
    assert(challengeOption.isSome.not(), "challenge already exists");
    const challenge = new Challenge({
      result: result,
      submitter: submitter,
      deadlineBlocks: this.network.block.height.add(durationBlocks),
      reward: reward,
      mostConfirmedHash: Field(0),
      mostConfirmedCount: UInt64.from(0),
      totalConfirmations: UInt64.from(0),
    });
    this.challenges.set(input, challenge);
  }

  public _checkNullifier(
    input: Field,
    address: PublicKey,
    raiseIfExists: boolean,
  ): void {
    const nullifier = new Nullifier({
      input: input,
      address: address,
    });
    const nullifierOption = this.nullifiers.get(nullifier);
    raiseIfExists
      ? assert(nullifierOption.isSome, "nullifer exists")
      : assert(nullifierOption.isSome.not(), "nullifer does not exist");
  }

  public _setNullifier(input: Field, address: PublicKey): void {
    const nullifier = new Nullifier({
      input: input,
      address: address,
    });

    this.nullifiers.set(nullifier, Bool(false));
  }

  public _checkReward(input: Field, address: PublicKey): Bool {
    const nullifier = new Nullifier({
      input: input,
      address: address,
    });

    return this.nullifiers.get(nullifier).orElse(Bool(false));
  }

  public _setReward(input: Field, address: PublicKey): void {
    this._checkNullifier(input, address, false);
    const nullifier = new Nullifier({
      input: input,
      address: address,
    });

    return this.nullifiers.set(nullifier, Bool(false));
  }

  public _getResult(input: Field, address: PublicKey): Field {
    const result = new ResultID({
      input: input,
      address: address,
    });
    return this.results.get(result).value;
  }

  public _setResult(input: Field, address: PublicKey, hash: Field): void {
    const result = new ResultID({
      input: input,
      address: address,
    });
    this.results.set(result, hash);
  }

  public _getResultCount(input: Field, result: Field): UInt64 {
    const resultCount = new ResultCountID({
      input: input,
      result: result,
    });

    return this.resultCounts.get(resultCount).orElse(UInt64.from(0));
  }

  public _incrementResultCount(input: Field, result: Field): void {
    const challenge = unwrap(
      this.challenges.get(input),
      " challenge input is invalid",
    );
    const resultCount = new ResultCountID({
      input: input,
      result: result,
    });
    const count = this.resultCounts.get(resultCount).orElse(UInt64.from(0));
    const newCount = count.add(1);
    this.resultCounts.set(resultCount, newCount);
    const newTotalCount = challenge.totalConfirmations.add(1);

    let updatedChallenge = new Challenge({
      ...challenge,
      totalConfirmations: newTotalCount,
    });

    if (newCount > challenge.mostConfirmedCount) {
      updatedChallenge = new Challenge({
        ...updatedChallenge,
        mostConfirmedHash: result,
        mostConfirmedCount: newCount,
      });
    }

    this.challenges.set(input, updatedChallenge);
  }

  @runtimeMethod()
  public confirm(
    input: Field,
    result: Field,
    preimageProof: PreimageProof,
  ): void {
    const address = this.transaction.sender.value;
    const challenge = unwrap(this.challenges.get(input), "challenge not found");
    assert(
      challenge.reward.greaterThan(UInt64.from(0)),
      "deadline for challenge has passed",
    );
    this._checkNullifier(input, address, true);
    preimageProof.verify();
    preimageProof.publicInput.assertEquals(result);
    this._setResult(input, address, result);
    this._incrementResultCount(input, result);
    this._setNullifier(input, address);
  }

  @runtimeMethod()
  public claim(input: Field): void {
    const address = this.transaction.sender.value;
    const challenge = unwrap(this.challenges.get(input), "challenge not found");
    assert(
      challenge.reward.greaterThan(UInt64.from(0)),
      "challenge has no reward",
    );
    const deadlinePassed = challenge.deadlineBlocks.lessThanOrEqual(
      this.network.block.height,
    );
    assert(deadlinePassed, "deadline for job has not yet passed");
    const result = new ResultID({
      input: input,
      address: address,
    });
    this._checkNullifier(input, address, false);
    this._checkReward(input, address);
    const resultHash = this.results.get(result).orElse(Field(0));
    assert(
      resultHash.equals(challenge.mostConfirmedHash),
      "your hash was not most confirmed",
    );
    const reward = challenge.reward.div(challenge.mostConfirmedCount);
    this.balances._mint(address, reward);
  }

  @runtimeMethod()
  public slash(input: Field): void {
    const challenge = unwrap(this.challenges.get(input), "challenge not found");
    challenge.result.assertNotEquals(challenge.mostConfirmedHash);
    const submitterBalance = this.balances._getAmount(challenge.submitter);
    const amount = submitterBalance
      .mul(this.config.slashAmount)
      .div(UInt64.from(100));
    this.balances._burn(challenge.submitter, amount);
  }
}
