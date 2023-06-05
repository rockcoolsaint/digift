FROM ruby:3.0.1-alpine3.13
# FROM ruby:3-alpine

ARG BUNDLER_VERSION=2.2.17

ENV PORT=3000

RUN apk add --update --no-cache \
      binutils-gold \
      build-base \
      curl \
      file \
      g++ \
      gcc \
      git \
      less \
      libstdc++ \
      libffi-dev \
      libc-dev \
      linux-headers \
      libxml2-dev \
      libxslt-dev \
      libgcrypt-dev \
      make \
      netcat-openbsd \
      nodejs \
      openssl \
      pkgconfig \
      postgresql-dev \
      python3 \
      tzdata \
      yarn

RUN gem install bundler:${BUNDLER_VERSION}

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle config build.nokogiri --use-system-libraries

RUN bundle check || bundle install

# COPY package.json yarn.lock ./

# RUN yarn install --check-files

COPY . ./

EXPOSE ${PORT}

ENTRYPOINT ["./entrypoints/docker-entrypoint.sh"]