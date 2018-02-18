FROM elixir:alpine

RUN mkdir ./project
WORKDIR ./project

COPY mix.exs .
COPY lib ./lib

RUN mix compile
