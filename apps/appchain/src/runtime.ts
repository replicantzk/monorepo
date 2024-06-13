import { UInt64 } from "o1js";
import { Balances } from "./runtime/balance";
import { Stake } from "./runtime/stake";
import { Challenges } from "./runtime/challenge";
import { Inference } from "./runtime/attest";

export default {
  modules: {
    Balances,
    Stake,
    Challenges,
    Inference,
  },
  config: {
    Balances: {},
    Stake: {},
    Challenges: {
      slashAmount: UInt64.from(33),
    },
    Inference: {
      claimReward: UInt64.from(1),
      challengeReward: UInt64.from(1),
      challengePeriod: UInt64.from((4 * 60 * 60) / 5), // 4 hours with 5 seconds blocks
    },
  },
};
