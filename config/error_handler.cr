Lucky::ErrorHandler.configure do |settings|
  settings.show_debug_output = false # !Lucky::Env.production?
end
