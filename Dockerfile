FROM elixir:1.6.1 AS builder

LABEL name="slack_quiet"
LABEL version="1.0.0"
LABEL maintainer="dstratta@sophilabs.com"

ARG APP_NAME=slack_quiet

ENV MIX_ENV=${MIX_ENV:-prod}
ENV REPLACE_OS_VARS=true

# Install the hex package manager.
RUN mix local.hex --force

# We need Erlang's build tool too.
RUN mix local.rebar --force

RUN mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez --force

# Create and change current directory.
WORKDIR /usr/src/app

# Install dependencies.
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

# Bundle app source.
COPY . .

RUN mix do deps.compile, compile

RUN mix release --env=prod --verbose \
    && mv _build/prod/rel/${APP_NAME} /opt/release \
    && mv /opt/release/bin/${APP_NAME} /opt/release/bin/start_server

FROM alpine:latest

RUN apk update && apk --no-cache --update add bash openssl-dev musl

ENV MIX_ENV=prod REPLACE_OS_VARS=true

WORKDIR /opt/app

COPY --from=builder /opt/release .

CMD ["/opt/app/bin/start_server", "foreground"]
