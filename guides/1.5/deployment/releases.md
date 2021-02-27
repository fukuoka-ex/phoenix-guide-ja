---
layout: 1.5/layout
version: 1.5
group: deployment
title: Deploying with Releases
nav_order: 2
hash: 8ab5fa52
---
# Deploying with Releases

## What we'll need

The only thing we'll need for this guide is a working Phoenix application. For those of us who need a simple application to deploy, please follow the [Up and Running guide](up_and_running.html).

## Goals

Our main goal for this guide is to package your Phoenix application into a self-contained directory that includes the Erlang VM, Elixir, all of your code and dependencies. This package can then be dropped into a production machine.

## Releases, assemble!

To assemble a release, you will need Elixir v1.9 or later:

```console
$ elixir -v
1.9.0
```

If you are not familiar with Elixir releases yet, we recommend you to read [Elixir's excellent docs](https://hexdocs.pm/mix/Mix.Tasks.Release.html) before continuing.

Once that is done, you can assemble a release by going through all of the steps in our general [deployment guide](deployment.html) with `mix release` at the end. Let's recap.

First set the environment variables:

```console
$ mix phx.gen.secret
REALLY_LONG_SECRET
$ export SECRET_KEY_BASE=REALLY_LONG_SECRET
$ export DATABASE_URL=ecto://USER:PASS@HOST/database
```

Then load dependencies to compile code and assets:

```console
# Initial setup
$ mix deps.get --only prod
$ MIX_ENV=prod mix compile

# Install / update  JavaScript dependencies
$ npm install --prefix ./assets

# Compile assets
$ npm run deploy --prefix ./assets
$ mix phx.digest
```

*Note:* the `--prefix` flag on `npm` may not work on Windows. If so, replace the first command by `cd assets && npm run deploy && cd ..`.

And now run `mix release`:

```console
$ MIX_ENV=prod mix release
Generated my_app app
* assembling my_app-0.1.0 on MIX_ENV=prod
* skipping runtime configuration (config/releases.exs not found)

Release created at _build/prod/rel/my_app!

    # To start your system
    _build/prod/rel/my_app/bin/my_app start

...
```

You can start the release by calling `_build/prod/rel/my_app/bin/my_app start`, where you have to replace `my_app` by your current application name. If you do so, your application should start but you will notice your web server does not actually run! That's because we need to tell Phoenix to start the web servers. When using `mix phx.server`, the `phx.server` command does that for us, but in a release we don't have Mix (which is a *build* tool), so we have to do it ourselves.

Open up `config/prod.secret.exs` and you should find a section about "Using releases" with a configuration to set. Go ahead and uncomment that line or manually add the line below, adapted to your application names:

```elixir
config :my_app, MyApp.Endpoint, server: true
```

Now assemble the release once again:

```console
$ MIX_ENV=prod mix release
Generated my_app app
* assembling my_app-0.1.0 on MIX_ENV=prod
* skipping runtime configuration (config/releases.exs not found)

Release created at _build/prod/rel/my_app!

    # To start your system
    _build/prod/rel/my_app/bin/my_app start
```

And starting the release now should also successfully start the web server! Now you can get all of the files under the `_build/prod/rel/my_app` directory, package it, and run it in any production machine with the same OS and architecture as the one that assembled the release. For more details, check the [docs for `mix release`](https://hexdocs.pm/mix/Mix.Tasks.Release.html).

But before we finish this guide, there are two features from releases most Phoenix applications will use, so let's talk about those.

## Runtime configuration

You may have noticed that, in order to assemble our release, we had to set both `SECRET_KEY_BASE` and `DATABASE_URL`. That's because `config/config.exs`, `config/prod.exs`, and friends are executed when the release is assembled (or more generally speaking, whenever you run a `mix` command).

However, in many cases, we don't want to set the values for `SECRET_KEY_BASE` and `DATABASE_URL` when assembling the release but only when starting the system in production. In particular, you may not even have those values easily accessible, and you may have to reach out to another system to retrieve those. Luckily, for such use cases, `mix release` provides runtime configuration, which we can enable in three steps:

1. Rename `config/prod.secret.exs` to `config/releases.exs`

2. Change `use Mix.Config` inside the new `config/releases.exs` file to `import Config` (if you want, you can replace all uses of `use Mix.Config` by `import Config`, as the latter replaces the former)

3. Change `config/prod.exs` to no longer call `import_config "prod.secret.exs"` at the bottom

Now if you assemble another release, you should see this:

```console
$ MIX_ENV=prod mix release
Generated my_app app
* assembling my_app-0.1.0 on MIX_ENV=prod
* using config/releases.exs to configure the release at runtime
```

Notice how it says you are using runtime configuration. Now you no longer need to set those environment variables when assembling the release, only when you run `_build/prod/rel/my_app/bin/my_app start` and friends.

## Ecto migrations and custom commands

Another common need in production systems is to execute custom commands required to set up the production environment. One of such commands is precisely migrating the database. Since we don't have `Mix`, a *build* tool, inside releases, which are a production artifact, we need to bring said commands directly into the release.

Our recommendation is to create a new file in your application, such as `lib/my_app/release.ex`, with the following:

```elixir
defmodule MyApp.Release do
  @app :my_app

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
```

Where you replace the first two lines by your application names.

Now you can assemble a new release with `MIX_ENV=prod mix release` and you can invoke any code, including the functions in the module above, by calling the `eval` command:

```console
$ _build/prod/rel/my_app/bin/my_app eval "MyApp.Release.migrate"
```

And that's it!

You can use this approach to create any custom command to run in production. In this case, we used `load_app`, which calls `Application.load/1` to load the current application without starting it. However, you may want to write a custom command that starts the whole application. In such cases, `Application.ensure_all_started/1` must be used. Keep in mind starting the application will start all processes for the current application, including the Phoenix endpoint. This can be circumvented by changing your supervision tree to not start certain children under certain conditions. For example, in the release commands file you could do:

```elixir
defp start_app do
  load_app()
  Application.put_env(@app, :minimal, true)
  Application.ensure_all_started(@app)
end
```

And then in your application you check `Application.get_env(@app, :minimal)` and start only part of the children when it is set.

## Containers

Elixir releases work well with container technologies, such as Docker. The idea is that you assemble the release inside the Docker container and then build an image based on the release artifacts.

Here is an example Docker file to run at the root of your application covering all of the steps above:

```docker
FROM elixir:1.9.0-alpine AS build

# install build dependencies
RUN apk add --no-cache build-base npm git python

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

# build assets
COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

COPY priv priv
COPY assets assets
RUN npm run --prefix ./assets deploy
RUN mix phx.digest

# compile and build release
COPY lib lib
# uncomment COPY if rel/ exists
# COPY rel rel
RUN mix do compile, release

# prepare release image
FROM alpine:3.9 AS app
RUN apk add --no-cache openssl ncurses-libs

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/my_app ./

ENV HOME=/app

CMD ["bin/my_app", "start"]
```

At the end, you will have an application in `/app` ready to run as `bin/my_app start`.
