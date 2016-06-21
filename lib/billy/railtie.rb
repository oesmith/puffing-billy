# Deprecated
require 'billy/browsers/capybara'
require 'billy/init/railtie'

Billy::Browsers::Capybara.register_drivers

warn "[DEPRECATION] `require 'billy/railtie'` is deprecated. Please use `require 'billy/capybara/railtie'` instead."
