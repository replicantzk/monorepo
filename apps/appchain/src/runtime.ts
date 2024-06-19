import { UInt64 } from "o1js";
import { Inference } from "./runtime/attest";
import { Balances } from "./runtime/balance";
import { Challenges } from "./runtime/challenge";
import { Stake } from "./runtime/stake";

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
      challengePeriod: UInt64.from((4 * 60 * 60) / 5),
    },
  },
};
