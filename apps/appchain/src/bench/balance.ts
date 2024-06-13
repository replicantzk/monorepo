#!/usr/bin/env node --experimental-specifier-resolution=node --experimental-vm-modules --experimental-wasm-modules --experimental-wasm-threads

import { PrivateKey } from "o1js";
import { sleep } from "@proto-kit/common";
import Client from "mina-signer";
import { client as appChain } from "../client.config";
import * as tx from "../client/index";
import { DEFAULT_BLOCK_INTERVAL, run } from "../bin/start";

const signerClient = new Client({ network: "testnet" });
const keys = signerClient.genKeys();
const signer = PrivateKey.fromBase58(keys.privateKey);

// Needs tx nonces to properly benchmark
export async function bench(
  rps: number = 1,
  seconds: number = 20,
  sleepBlocks: number = 10
) {
  run();

  const amount = 10;
  let total = 0;
  let txCount = 0;
  let secondsCount = 0;

  setInterval(async () => {
    try {
      if (secondsCount >= seconds) {
        await sleep(sleepBlocks * DEFAULT_BLOCK_INTERVAL);
        const chainTotal = await appChain.query.runtime.Balances.amounts.get(
          signer.toPublicKey()
        );
        console.log(`MINTED LOCAL: ${total} VS CHAIN: ${chainTotal}`);
        process.exit();
      }

      for (let i = 0; i < rps; i++) {
        txCount++;
        console.log(`tx #${txCount}`);
        await tx.balances.mint(appChain, signer, amount);
        total += amount;
      }
      secondsCount++;
    } catch (e) {
      console.error(e);
      process.exit();
    }
  }, 1000);
}

bench();
