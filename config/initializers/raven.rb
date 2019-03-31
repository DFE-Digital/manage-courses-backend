# coding: utf-8

Raven.configure do |config|
  # Let’s not exclude ActiveRecord::RecordNotFound from Sentry
  # https://github.com/getsentry/raven-ruby/wiki/Advanced-Configuration#excluding-exceptions
  config.excluded_exceptions = Raven::Configuration::IGNORE_DEFAULT -
    ['ActiveRecord::RecordNotFound']
end

def bat_environment
  Raven.tags_context(bat_environment: ENV['SENTRY_ENVIRONMENT'])
end
