ARG DEBIAN_VERSION=bullseye-20240311-slim
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"
ARG OTP_VERSION=25.2.3
ARG ELIXIR_VERSION=1.16.2
# ARG NODE_VERSION=18

# FROM hexpm/elixir:1.16.2-erlang-25.2.3-debian-bullseye-20240311-slim as base

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION} as base

# ENV NODE_VERSION=${NODE_VERSION}
ENV NODE_VERSION=18

RUN apt-get update -y && apt-get install -y \
  build-essential \
  curl \
  git

RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
  apt-get install -y nodejs
RUN npm -v

RUN mkdir -p /app/platform

WORKDIR /app/platform

COPY . .

# install hex + rebar
RUN mix local.hex --force && \
  mix local.rebar --force

FROM base as dev

# set build ENV
ENV MIX_ENV="dev"

# install mix dependencies
# COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
# RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
# COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# COPY priv priv

# COPY lib lib

# COPY assets assets

# compile assets
WORKDIR /app/platform/assets
RUN npm install
WORKDIR /app/platform

RUN mix assets.deploy

# Compile the release
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
# COPY config/runtime.exs config/

# COPY rel rel
# RUN mix release

FROM base as builder

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
# COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
# RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
# COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# COPY priv priv

# COPY lib lib

# COPY assets assets

# compile assets
WORKDIR /app/platform/assets
RUN npm install
WORKDIR /app/platform

RUN mix assets.deploy

# Compile the release
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
# COPY config/runtime.exs config/

# COPY rel rel
RUN mix release

FROM ${RUNNER_IMAGE} as build

RUN apt-get update -y && \
  apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/platform/_build/${MIX_ENV}/rel/platform ./

USER nobody

# If using an environment that doesn't automatically reap zombie processes, it is
# advised to add an init process such as tini via `apt-get install`
# above and adding an entrypoint. See https://github.com/krallin/tini for details
# ENTRYPOINT ["/tini", "--"]

CMD ["/app/bin/server"]
