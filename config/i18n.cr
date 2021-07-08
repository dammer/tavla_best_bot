I18n.backend = I18n::Backends::YAML.new.tap do |backend|
  backend.load_paths << Dir.current + "/config/locales"
  backend.load
end
I18n.available_locales = %w(en ru tr)
I18n.default_locale = "en"
I18n.rescue_missing = true

def with_locale(locale)
  unless I18n.available_locales.includes?(locale)
    locale = I18n.default_locale
  end
  I18n.locale = locale
  yield
ensure
  I18n.locale = I18n.default_locale
end
