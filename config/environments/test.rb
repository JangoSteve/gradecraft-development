GradeCraft::Application.configure do
  config.action_controller.allow_forgery_protection = false
  config.asset_host = "http://localhost:5000"
  config.action_mailer.default_url_options = { :host => 'localhost:5000' }
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = false
  config.action_mailer.delivery_method = :test
  config.active_support.deprecation = :stderr
  config.cache_classes = true
  config.eager_load = false
  config.serve_static_files = true
  config.static_cache_control = "public, max-age=3600"
  config.session_store :cookie_store, key: '_gradecraft_session', :expire_after => 60.minutes
end

CarrierWave.configure do |config|
  config.storage = :file
  config.enable_processing = false
end

# List tested uploaders here to make sure they are auto-loaded
# This assures files are created in spec/support/uploads and can be deleted after tests
AttachmentUploader

CarrierWave::Uploader::Base.descendants.each do |klass|
  next if klass.anonymous?
  klass.class_eval do
    def cache_dir
      "#{Rails.root}/spec/support/uploads/tmp"
    end
  end
end
