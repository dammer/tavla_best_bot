# Load .env file before any other config or app code
require "dotenv"
Dotenv.load?

# Require your shards here
require "avram"
require "lucky"
require "carbon"
require "authentic"
require "tourmaline"
require "i18n"
require "i18n/backends/yaml"
