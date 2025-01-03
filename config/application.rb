require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SwapLoot
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.active_job.queue_adapter = :sidekiq
    config.autoload_paths += %W(#{config.root}/lib)

    # config.after_initialize do
    #   if Rails.env.production? || Rails.env.development?
    #     PermanentDeleteJob.set(wait_until: Date.tomorrow.to_time).perform_later
    #     PriceEmpireSuggestedPriceJob.set(wait_until: Date.tomorrow.to_time).perform_later
    #   end
    # end
    config.action_cable.mount_path = '/cable'
    config.action_cable.disable_request_forgery_protection = true


    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil
    Bundler.require(*Rails.groups)

    # Load dotenv only in development or test environment
    if ['development', 'test'].include? ENV['RAILS_ENV']
      Dotenv::Railtie.load
    end

    HOSTNAME = ENV['HOSTNAME']
  end
end
