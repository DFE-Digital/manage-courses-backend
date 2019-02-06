[![Build Status](https://travis-ci.org/DFE-Digital/manage-courses-backend.svg?branch=master)](https://travis-ci.org/DFE-Digital/manage-courses-backend)

# Manage Courses Backend

## Prerequisites

### Native

- Ruby 2.6.1
- postgresql-9.6 postgresql-contrib-9.6

### Docker

- docker
- docker-compose

## Setting up the app in development

### Native

1. Run `bundle install` to install the gem dependencies
2. Run `rails db:setup` to create a development and testing database
3. Run `bundle exec rails server` to launch the app on http://localhost:3000.

### Docker

Run this in a shell and leave it running:

```
docker-compose up --build --detach
```

You can then follow the log output with

```
docker-compose logs --follow
```

The first time you run the app, you need to set up the databases. With the above command running separately, do:

```
docker-compose exec web /bin/sh -c "bundle exec rails db:setup"
```

Then open http://localhost:3000 to see the app.

## Accessing API

[See API Docs](https://github.com/DFE-Digital/manage-courses-backend/blob/master/docs/api.md)

Quick check that it's working in local development with the token "bats"
configured in `config/environments/development.rb`:

```bash
curl http://localhost:3000/api/v1/2019/subjects.json -H "Authorization: Bearer bats"
```

## Linting

It's best to lint just your app directories and not those belonging to the framework:

```bash
bundle exec govuk-lint-ruby app config db lib spec --format clang

or

docker-compose exec web /bin/sh -c "bundle exec govuk-lint-ruby app config db lib spec --format clang"
```

## CI variables

You'll need to define the `AZURE_CR_PASSWORD` in Travis in order to successfully build and publish. This can be done using this command:

```bash
travis encrypt AZURE_CR_PASSWORD="xxx" --add
```

## Sentry

To track exceptions through Sentry, configure the `SENTRY_DSN` environment variable:

```
SENTRY_DSN=https://aaa:bbb@sentry.io/123 rails s
```
