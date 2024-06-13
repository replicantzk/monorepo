#!/usr/bin/env node --experimental-specifier-resolution=node --experimental-vm-modules --experimental-wasm-modules --experimental-wasm-threads

import { ManualBlockTrigger } from "@proto-kit/sequencer";
import appChain from "../chain.config.js";

export const DEFAULT_BLOCK_INTERVAL = 5000;

export async function run(interval: number = DEFAULT_BLOCK_INTERVAL) {
  console.log("starting...");
  await appChain.start();
  const trigger = appChain.sequencer.resolveOrFail(
    "BlockTrigger",
    ManualBlockTrigger
  );
  setInterval(async () => {
    const now = new Date().toLocaleTimeString();
    console.log(`block: ${now}`);
    try {
      await trigger.produceUnproven();
    } catch (e) {
      console.error(e);
    }
  }, interval);
}
