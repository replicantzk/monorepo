# Replicant Network

![logo](./assets/logo_small.png)

*Own your intelligence.*

The Replicant Network is an open-source decentralized AI inference network. Download the desktop app to earn credits for serving requests routed to you from our OpenAI-compatible API. Credits are used to make requests to the API, and a minimum balance is currently required to participate as a worker to mitigate abuse. You can request this initial balance in the [Discord](https://discord.gg/yvWPVCS7NH) server. Start with the [TLDR](https://replicantzk.com/about/tldr) and [quickstart](https://replicantzk.com/docs/quickstart/api) guides on our [site](https://replicantzk.com) to learn more.

## Components

Components labeled `(experimental)` are in development to enable permisionless participation and provide assurances for response integrity.

```bash
.
├── apps
│   ├── appchain # (experimental) Mina/Protokit ZK appchain
│   ├── onchain # (experimental) EVM contracts and Noir circuits
│   ├── platform # Main service
│   ├── site # Website and documentation
│   ├── worker_app # Worker desktop application
│   ├── worker_cli # Worker command line application
│   └── worker_sdk # Shared JS code for worker applications
├── assets # Shared static assets
├── sh # Shell scripts
└── vendor # External repositories
    ├── chat # Gradio ChatInterface demo
    └── protokit # `appchain` dependency

```

## Developing

### Tools

- [docker](https://docs.docker.com/engine/install)
- [docker compose](https://docs.docker.com/compose/install)
- [mise](https://mise.jdx.dev/getting-started.html)
- [asdf elixir](https://github.com/asdf-vm/asdf-elixir)
- [poetry](https://python-poetry.org/docs/#installing-with-pipx)
- [solc](https://docs.soliditylang.org/en/latest/installing-solidity.html#installing-the-solidity-compiler)
- [direnv](https://direnv.net/docs/installation.html)

### Setup

(These instructions and the shell scripts in the project assume a Debian-based Linux distribution.)

Copy the file `.env_` to `.env` and fill in the required values.

Set up the apps by running:

```bash
sudo apt-get install unzip
mise plugin add elixir https://github.com/asdf-vm/asdf-elixir.git
chmod +x ./sh/setup.sh
./sh/setup.sh
direnv allow
```

Each component may require it's own individual setup ex. setting up the database with `sh/db.sh` and `mix setup` before being using `sh/start.sh` to run the app in `./apps/platform`. 

You can also run all the components in containers by running:

```bash
docker compose build
docker compose up
```

## License

[MIT](./LICENSE.md)
