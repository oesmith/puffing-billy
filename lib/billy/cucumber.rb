# Deprecated
require 'capybara/cucumber'
require 'billy/browsers/capybara'
require 'billy/init/cucumber'

Billy::Browsers::Capybara.register_drivers

warn "[DEPRECATION] `require 'billy/cucumber'` is deprecated. Please use `require 'billy/capybara/cucumber'` instead."
