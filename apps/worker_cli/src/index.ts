import { Command, Option } from "commander";
import { generateWorkerSalt, workerStatus, startWorker } from "worker_sdk";

const program = new Command();

program
  .addOption(
    new Option("-m, --modelName <modelName>", "Model name")
      .env("WORKER_MODEL")
      .makeOptionMandatory()
  )
  .addOption(
    new Option("-k, --workerAPIKey <workerAPIKey>", "API key")
      .env("WORKER_API_KEY")
      .makeOptionMandatory()
  )
  .addOption(
    new Option("-s, --workerSalt <workerSalt>", "worker ID salt")
      .env("WORKER_SALT")
      .default(generateWorkerSalt())
  )
  .addOption(
    new Option("-us, --urlServer <urlServer>", "URL of the socket server")
      .env("WORKER_URL_SERVER")
      .default("wss://platform.replicantzk.com")
  )
  .addOption(
    new Option("-ul, --urlLLM <urlLLM>", "URL of the LLM server")
      .env("WORKER_URL_LLM")
      .default("http://localhost:11434")
  );

program.parse();
const opts = program.opts();

function consoleMessageFn(message: string, _status?: workerStatus) {
  console.log(`LOG: ${message}`);
}

const displayOpts = { ...opts };
delete displayOpts.workerAPIKey;
delete displayOpts.workerSalt;
consoleMessageFn(`Starting worker with options: ${JSON.stringify(displayOpts)}`);

await startWorker({
  messageFn: consoleMessageFn,
  modelName: opts.modelName,
  APIKey: opts.workerAPIKey,
  salt: opts.workerSalt,
  urlServer: opts.urlServer,
  urlLLM: opts.urlLLM
});
